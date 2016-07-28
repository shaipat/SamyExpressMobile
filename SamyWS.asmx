<%@ WebService Language="C#" Class="SamySpace.SamyWS" %>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Web.Script.Serialization;
using System.Web.Services;


namespace SamySpace
{
    /// <summary>
    /// Summary description for SamyWS
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.Web.Script.Services.ScriptService]

    public class SamyWS : System.Web.Services.WebService
    {
        DB db = new DB();

        [WebMethod]
        public string GetUserIdByEmail(string email)
        {
            return db.GetUserIdByEmail(email);
        }


        [WebMethod]
        public List<Product> GetUserProductsById(string OrderBy, string StatusFilter, string UserId)
        {
            return db.GetUserProductsById(OrderBy, StatusFilter, UserId);
        }


        [WebMethod]
        public void NotificationHandler()
        {
            string now = DateTime.Now.ToShortDateString();
            string last = (string)Application["Dispute"] ?? "undefined";

            if (last == now)
                return;

            Application["Dispute"] = now;
            DailyDisputeCheck();
        }

        [WebMethod]
        public void DailyDisputeCheck()
        {
            int daysToReminder;

            if (!int.TryParse((string)Application["DaysToRemind"], out daysToReminder))
                daysToReminder = 5;

            DB db = new DB();

            List<Product> prods = db.GetAllProducts();

            int emailsCount = 0;

            foreach (var prod in prods)
            {
                int timeRemain = prod.DaysRemainToCase;

                if (timeRemain > 0 && timeRemain < daysToReminder)
                {
                    // send notification
                    string msg = "This is reminder for product \"" + prod.Name + "\"\nYou have " + prod.DaysRemainToCase + " days to open dispute.\n\n Yours, SamyExpress Team";
                    MailSender.SendMail(prod.UserEmail, "SamyExpress - Dispute reminder for \"" + prod.Name + "\"", msg);
                    emailsCount++;
                }
            }
            string adminMsg = " Hello admin,\nDailyDisputeCheck function has executed at " + DateTime.Now.ToShortDateString() + " " + DateTime.Now.ToShortTimeString() +
                              "\nTotal email sent : " + emailsCount;
            MailSender.SendMail("maort22@gmail.com", "SamyExpress - Admin notifications", adminMsg);

        }


        [WebMethod]
        public string GetSummary(int UserId)
        {
            return db.GetSummary(UserId);
        }

        [WebMethod]
        public Product GetProductById(int Id)
        {
            return db.GetProductById(Id);

        }

        [WebMethod]
        public void AddProduct(string Name, string Price, string OrderDate, string DaysToCase, string Status, string TrackingNumber, string Url, string PicUrl,string UserId)
        {
            db.AddProduct(Name, Price, OrderDate, DaysToCase, Status, TrackingNumber, Url, PicUrl, UserId);
        }

        [WebMethod]
        public void UpdateProduct(string Id, string Name, string Price, string OrderDate, string DaysToCase, string Status, string TrackingNumber, string Url, string PicUrl)
        {
            db.UpdateProduct(Id, Name, Price, OrderDate, DaysToCase, Status, TrackingNumber, Url, PicUrl);
        }

        [WebMethod]
        public void MarkArrived(string Id)
        {
            db.MarkArrived(Id);
        }

        [WebMethod]
        public void DeleteProductById(int Id)
        {
            db.DeleteProductById(Id);
        }

        [WebMethod]
        public void DeleteAllProducts()
        {
            db.DeleteAllProducts();
        }


        [WebMethod]
        public void SetDaysToRemind(string days)
        {
            Application["DaysToRemind"] = days;
        }


        [WebMethod]
        public string GetDaysToRemind()
        {
            return (string)Application["DaysToRemind"] ?? "5";
        }

        [WebMethod]
        public void SetTrackNotificationById(string UserId, string Track)
        {
            db.SetTrackNotificationById(UserId, Track);
        }


        [WebMethod]
        public string GetTrackNotificationById(string UserId)
        {
            return db.GetTrackNotificationById(UserId);
        }
        
    }

    //------------------------------------------------
    //---------------- DB CLASS -------------------
    //------------------------------------------------
    #region DB CLASS
    public class DB
    {

        public string GetUserIdByEmail(string email)
        {
            int Id = 0;
            SqlCommand cmd = new SqlCommand("DECLARE @result int;  " +
                                            "EXECUTE Get_User_Id @Email, " +
                                            "@result OUTPUT ; " +
                                            "SELECT @result");
            cmd.Parameters.AddWithValue("@Email", email);
            Id = ExeSqlScalar(cmd);
            return Id.ToString();
        }

        public string GetSummary(int UserId)
        {
            int NumOfOrders = 0;
            int OnTheWay = 0;
            float TotalExpenses = 0;
            int OpenedCases = 0;


            #region NumOfOrders

            //SqlConnection con = new SqlConnection(constr);
            SqlConnection con = GetSqlConnection();
            SqlCommand cmd = new SqlCommand("SELECT Count(*) as count from Product WHERE UserId=@UserId", con);
            cmd.Parameters.AddWithValue("@UserId", UserId);

            con.Open();
            SqlDataReader reader = cmd.ExecuteReader();

            if (reader.Read())
                NumOfOrders = Int32.Parse(reader["count"].ToString());

            con.Close();


            #endregion

            #region OnTheWay

            con.Open();
            cmd.CommandText = "SELECT Count(*) as count from Product where UserId=@UserId AND Status = N'OnTheWay' OR Status = N'Case'";
            reader = cmd.ExecuteReader();


            if (reader.Read())
                OnTheWay = Int32.Parse(reader["count"].ToString());

            con.Close();

            #endregion

            #region TotalExpenses

            con.Open();
            cmd.CommandText = "SELECT SUM(Price) as count from Product where status <> N'Closed' AND UserId=@UserId";
            reader = cmd.ExecuteReader();


            if (reader.Read())
                float.TryParse(reader["count"].ToString(), out TotalExpenses);

            con.Close();

            #endregion

            #region OpenedCases


            con.Open();
            cmd.CommandText = "SELECT Count(*) as count from Product where Status = N'Cased' AND UserId=@UserId";
            reader = cmd.ExecuteReader();

            if (reader.Read())
                OpenedCases = Int32.Parse(reader["count"].ToString());

            con.Close();

            #endregion

            var summary = new
            {
                numOfOrders = NumOfOrders,
                onTheWay = OnTheWay,
                totalExpenses = TotalExpenses,
                openedCases = OpenedCases
            };

            var json = new JavaScriptSerializer().Serialize(summary);
            return json;
        }

        public List<Product> GetUserProductsById(string OrderBy, string StatusFilter, string UserId)
        {
            List<Product> productt = new List<Product> { };
            SqlCommand cmd = new SqlCommand();

            string sqlCom1, sqlCom2;

            switch (StatusFilter)
            {
                case "OnTheWay":

                    sqlCom1 =
                        "SELECT Id,Name,Price,OrderDate,DaysToCase,PicUrl FROM Product WHERE UserId=@UserId AND Status='OnTheWay' OR Status='Cased' ORDER BY ";
                    break;
                case "All":
                    sqlCom1 = "SELECT Id,Name,Price,OrderDate,DaysToCase,PicUrl FROM Product WHERE UserId=@UserId ORDER BY ";
                    break;
                default:
                    sqlCom1 = "SELECT Id,Name,Price,OrderDate,DaysToCase,PicUrl FROM Product WHERE UserId=@UserId ORDER BY ";
                    break;
            }

            switch (OrderBy)
            {
                case "OrderDate":
                    sqlCom2 = "OrderDate DESC";
                    break;
                case "Price":
                    sqlCom2 = "Price ASC";
                    break;
                case "Name":
                    sqlCom2 = "Name ASC";
                    break;
                default:
                    sqlCom2 = "OrderDate DESC";
                    break;
            }


            string sqlFullCommand = sqlCom1 + sqlCom2;

            cmd.CommandText = sqlFullCommand; ;
            cmd.Parameters.AddWithValue("@UserId", UserId);

            DataSet ds = GetData(cmd);
            foreach (DataRow item in ds.Tables[0].Rows)
            {
                Product pro = new Product();
                pro.Id = Convert.ToInt32(item["Id"].ToString());
                pro.Name = item["Name"].ToString();
                pro.Price = Convert.ToDouble(item["Price"]);
                pro.OrderDate = item["OrderDate"].ToString();
                pro.DaysToCase = Convert.ToInt32(item["DaysToCase"]);
                pro.DaysRemainToCase = Calc_Days_To_Case(pro.OrderDate, pro.DaysToCase);
                pro.PicUrl = item["PicUrl"].ToString();
                //   pro.Url = item["Url"].ToString();

                if (pro.PicUrl.Length == 0) // if there is no url for pic
                    pro.PicUrl = "Images/package-icon.png"; //todo: fix alt pic when no url specified
                productt.Add(pro);
            }
            return productt;
        }



        public List<Product> GetAllProducts()
        {
            List<Product> productList = new List<Product> { };
            SqlCommand cmd = new SqlCommand();

            string sqlCom = "SELECT Product.Id,Name,Price,OrderDate,DaysToCase,Url,PicUrl,Email " +
                             "FROM Product,[User] " +
                             "WHERE [User].Id = Product.UserId AND Status='OnTheWay' AND Track='True'";

            cmd.CommandText = sqlCom;

            DataSet ds = GetData(cmd);
            foreach (DataRow item in ds.Tables[0].Rows)
            {
                Product pro = new Product();
                pro.Id = Convert.ToInt32(item["Id"].ToString());
                pro.Name = item["Name"].ToString();
                pro.Price = Convert.ToDouble(item["Price"]);
                pro.OrderDate = item["OrderDate"].ToString();
                pro.DaysToCase = Convert.ToInt32(item["DaysToCase"]);
                pro.DaysRemainToCase = Calc_Days_To_Case(pro.OrderDate, pro.DaysToCase);
                pro.PicUrl = item["PicUrl"].ToString();
                pro.Url = item["Url"].ToString();
                if (pro.PicUrl.Length == 0) // if there is no url for pic
                    pro.PicUrl = "Images/package-icon.png"; //todo: fix alt pic when no url specified

                pro.UserEmail = item["Email"].ToString();

                productList.Add(pro);
            }

            return productList;
        }


        public Product GetProductById(int Id)
        {
            string query = "SELECT * FROM Product WHERE Id=@id";
            SqlCommand cmd = new SqlCommand(query);
            cmd.Parameters.AddWithValue("id", Id);
            DataSet ds = GetData(cmd);
            Product pro = new Product();
            foreach (DataRow item in ds.Tables[0].Rows)
            {
                pro.Id = Convert.ToInt32(item["Id"].ToString());
                pro.Name = item["Name"].ToString();
                pro.Price = Convert.ToDouble(item["Price"]);
                pro.OrderDate = item["OrderDate"].ToString();
                pro.DaysToCase = Convert.ToInt32(item["DaysToCase"].ToString());
                pro.DaysRemainToCase = Calc_Days_To_Case(pro.OrderDate, pro.DaysToCase);
                pro.TrackingNumber = item["TrackingNumber"].ToString();
                pro.TrackingInfo = GetTrackingInfo(pro.TrackingNumber);
                pro.Status = item["Status"].ToString();
                pro.Url = item["Url"].ToString();
                pro.PicUrl = item["PicUrl"].ToString();

                if (pro.PicUrl.Length == 0) // if there is no url for pic
                    pro.PicUrl = "Images/package-icon.png"; //todo: fix alt pic when no url specified        
            }
            return pro;
        }


        private static SqlConnection GetSqlConnection()
        {
            string cStr = @"Data Source=82.166.189.73;Initial Catalog=cegroup6Db;Persist Security Info=True;User ID=cegroup6;Password=cegroup6123";
            SqlConnection con = new SqlConnection(cStr);
            return con;
        }

        private void ExeSqlCommand(SqlCommand cmd)
        {
            using (GetSqlConnection())
            {

                cmd.Connection = GetSqlConnection();
                cmd.Connection.Open();
                cmd.ExecuteNonQuery();
                cmd.Connection.Close();
            }
        }

        private int ExeSqlScalar(SqlCommand cmd)
        {
            int Id = 0;
            using (GetSqlConnection())
            {
                cmd.Connection = GetSqlConnection();
                cmd.Connection.Open();
                Id = (int)cmd.ExecuteScalar();
                cmd.Connection.Close();
            }

            return Id;
        }

        public void AddProduct(string Name, string Price, string OrderDate, string DaysToCase, string Status,
            string TrackingNumber, string Url, string PicUrl,string UserId)
        {
            SqlCommand cmd =
                new SqlCommand(
                    "Insert into Product values(@Name,@Price,@OrderDate,@DaysToCase,@Status,'none',@TrackingNumber,@Url,@PicUrl,@UserId)");
            DateTime dt = DateTime.Now;
            DateTime.TryParse(OrderDate, out dt);
            if (dt.Year == 0001)
                dt = DateTime.Now;

            float price;

            float.TryParse(Price, out price);

            string fixed_date = dt.Month + "/" + dt.Day + "/" + dt.Year;

            cmd.Parameters.AddWithValue("@Name", Name);
            cmd.Parameters.AddWithValue("@Price", price);
            cmd.Parameters.AddWithValue("@OrderDate", fixed_date);
            cmd.Parameters.AddWithValue("@DaysToCase", DaysToCase);
            cmd.Parameters.AddWithValue("@Status", Status);
            cmd.Parameters.AddWithValue("@TrackingNumber", TrackingNumber);
            cmd.Parameters.AddWithValue("@Url", Url);
            cmd.Parameters.AddWithValue("@PicUrl", PicUrl);
            cmd.Parameters.AddWithValue("@UserId", UserId);
            ExeSqlCommand(cmd);
        }

        public void UpdateProduct(string Id, string Name, string Price, string OrderDate, string DaysToCase,
            string Status, string TrackingNumber, string Url, string PicUrl)
        {
            SqlCommand cmd = new SqlCommand("UPDATE Product SET Name=@Name,  Price=@Price,   OrderDate=@OrderDate," +
                                            "DaysToCase=@DaysToCase,   Status=@Status,   TrackingNumber=@TrackingNumber," +
                                            "Url=@Url,   PicUrl=@PicUrl" +
                                            " WHERE Id=@Id");
            DateTime dt;
            DateTime.TryParse(OrderDate, out dt);
            if (dt.Year == 0001)
                dt = DateTime.Now;
            string fixed_date = dt.Month + "/" + dt.Day + "/" + dt.Year;

            float price = 0;

            float.TryParse(Price, out price);

            cmd.Parameters.AddWithValue("@Id", Id);
            cmd.Parameters.AddWithValue("@Name", Name);
            cmd.Parameters.AddWithValue("@Price", price);
            cmd.Parameters.AddWithValue("@OrderDate", fixed_date);
            cmd.Parameters.AddWithValue("@DaysToCase", DaysToCase);
            cmd.Parameters.AddWithValue("@Status", Status);
            cmd.Parameters.AddWithValue("@TrackingNumber", TrackingNumber);
            cmd.Parameters.AddWithValue("@Url", Url);
            cmd.Parameters.AddWithValue("@PicUrl", PicUrl);
            ExeSqlCommand(cmd);
        }

        public void MarkArrived(string Id)
        {
            SqlCommand cmd = new SqlCommand("UPDATE Product SET Status='Arrived' WHERE Id=@Id");

            cmd.Parameters.AddWithValue("@Id", Id);
            ExeSqlCommand(cmd);
        }


        private static int Calc_Days_To_Case(string orderDate, int daysToCase)
        {
            DateTime oDate;
            DateTime.TryParse(orderDate, out oDate);
            int remain = (int) (oDate.AddDays(daysToCase) - DateTime.Now).TotalDays;
            if (remain < 0)
                remain = 0;
            return remain;
        }



        public void DeleteProductById(int Id)
        {
            SqlCommand cmd = new SqlCommand("DELETE FROM Product WHERE Id=@Id");
            cmd.Parameters.AddWithValue("@Id", Id);
            ExeSqlCommand(cmd);
        }


        public void DeleteAllProducts()
        {
            SqlCommand cmd = new SqlCommand("DELETE FROM Product");
            ExeSqlCommand(cmd);
        }

        private static DataSet GetData(SqlCommand cmd)
        {
            using (GetSqlConnection())
            {
                using (SqlDataAdapter sda = new SqlDataAdapter())
                {
                    cmd.Connection = GetSqlConnection();
                    sda.SelectCommand = cmd;
                    using (DataSet ds = new DataSet())
                    {
                        sda.Fill(ds);
                        return ds;
                    }
                }
            }
        }


        public string GetTrackingInfo(string trackNum)
        {
            if (trackNum.Length == 0)
            {
                return "לא קיים מידע";
            }

            string url = "http://www.israelpost.co.il/itemtrace.nsf/trackandtraceJSON?OpenAgent&lang=he-il&itemcode=" +
                         trackNum;

            using (WebClient wc = new WebClient())
            {
                //                wc.Encoding = System.Text.Encoding.UTF8;
                wc.Encoding = Encoding.UTF8;
                string json = wc.DownloadString(url);
                JavaScriptSerializer js = new JavaScriptSerializer();
                TrackingInfo info = js.Deserialize<TrackingInfo>(json);

                string res = info.itemcodeinfo;

                res = res.Remove(res.IndexOf("<br>"));
                return res;
            }
        }

        public void SetDaysToRemind(int numOfDays)
        {
            Product.daysToReminder = numOfDays;
        }

        private class TrackingInfo
        {
            public string itemcodeinfo;
            public string data_type;
            public string hasSignimage;
            public string hasimage;
            public string typename;
        }

        public void SetTrackNotificationById(string UserId, string Track)
        {
            SqlCommand cmd = new SqlCommand("UPDATE [User] SET Track=@Track WHERE Id=@Id");
            cmd.Parameters.AddWithValue("@Id", UserId);
            cmd.Parameters.AddWithValue("@Track", Track);
            ExeSqlCommand(cmd);
        }

        public string GetTrackNotificationById(string UserId)
        {
            SqlConnection con = GetSqlConnection();
            SqlCommand cmd = new SqlCommand("SELECT Track FROM [User] WHERE Id=@Id",con);
            cmd.Parameters.AddWithValue("@Id", UserId);
            string track = null;
            
            con.Open();
            SqlDataReader reader = cmd.ExecuteReader();
            if (reader.Read())
                track = reader["Track"].ToString();
            con.Close();
            return track;
        }
    }

    #endregion


    //------------------------------------------------
    //---------------- PRODUCT CLASS -------------------
    //------------------------------------------------
    #region Product Class
    public class Product
    {
        public int Id;
        public string Name;
        public double Price;
        public string OrderDate;
        public string Status;
        public string TrackingNumber;
        public string TrackingInfo;
        public string PicUrl;
        public string Url;
        public int DaysToCase;
        public int DaysRemainToCase;
        public string UserEmail;
        public static int daysToReminder = 5; // How many days before to send email notification

    }
    #endregion


    //------------------------------------------------
    //---------------- MAIL SENDER -------------------
    //------------------------------------------------
    public class MailSender
    {
        private static string smtp = "smtp.gmail.com";
        private static string sender = "SamyExpressServ@gmail.com";
        private static string mailUser = "SamyExpressServ";
        private static string mailPassword = "SaMyExP253";


        public static void SendMail(string emailTo, string subject, string messageBody)
        {
            string smtpAddress = "smtp.gmail.com";
            int portNumber = 587;
            bool enableSSL = true;

            string emailFrom = "SamyExpressServ@gmail.com";
            string password = "SaMyExP253";

            using (MailMessage mail = new MailMessage())
            {
                mail.From = new MailAddress(emailFrom);
                mail.To.Add(emailTo);
                mail.Subject = subject;
                mail.Body = messageBody;

                using (SmtpClient smtp = new SmtpClient(smtpAddress, portNumber))
                {
                    smtp.Credentials = new NetworkCredential(emailFrom, password);
                    smtp.EnableSsl = enableSSL;

                    smtp.Send(mail);
                }
            }
        }

    } //end of MailSender


}  //end of namespace

 
