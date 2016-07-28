

//Set WebService location
//var local = false;
//var WebServiceURL = "SamyWS.asmx";
//if (!local) {
//    WebServiceURL = "http://proj.ruppin.ac.il/cegroup14/prod/SamyWS.asmx";
//}

var imageSource;
var imageTaken = false;
var lastImageFilename;
var imageServerRoot = "http://proj.ruppin.ac.il/cegroup14/prod/products_images/";
var serverRoot = "http://proj.ruppin.ac.il/cegroup14/prod/";


//$("div[data-role='page']").not('#loginPage').load(function(event) {

//});

$(document).on("pagebeforeshow", "div[data-role='page']:not(#loginPage)", function (event) {
    CheckLogin();
});

//----------------------------------------------
// LOGIN
//----------------------------------------------
$(document).on("pagebeforeshow", "#loginPage", function (event) {

    if (localStorage.UserId == null) {
        localStorage.UserId = 0;
    }
    else if (localStorage.UserId != 0) {
        $.mobile.changePage('#homePage');
    }



    $('#btnLogin').unbind('click').click(function () {
        var email = $('#txtUserEmail').val();

        if (!ValitadeEmailFormat(email)) {
            alert("Please enter a valid email");
            return;
        }          
        GetUserIdByEmail(email);
        localStorage.UserEmail = email;
    });

});

function ValitadeEmailFormat(email) {
    var emailReg = new RegExp(/^(("[\w-\s]+")|([\w-]+(?:\.[\w-]+)*)|("[\w-\s]+")([\w-]+(?:\.[\w-]+)*))(@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$)|(@\[?((25[0-5]\.|2[0-4][0-9]\.|1[0-9]{2}\.|[0-9]{1,2}\.))((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){2}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\]?$)/i);
    return emailReg.test(email);
}


//----------------------------------------------
// HOME
//----------------------------------------------
$(document).on("pagebeforeshow", "#homePage", function (event) {

    if (localStorage.OrderBy == null)
        localStorage.OrderBy = "Date";
    //if (localStorage.Track == null)
    //    localStorage.Track = "true";

    wireEventsHomePage();


    // TEST APPLICATION // TEST APPLICATION // TEST APPLICATION // TEST APPLICATION
    $.ajax({
        url: WebServiceURL + "/NotificationHandler",
        dataType: "json",
        type: "POST",
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

        }
    });


});


function wireEventsHomePage() {

   // alert(localStorage.UserEmail.toString());

    $('#lblUserEmail').text(localStorage.UserEmail);

    $('#btnLogout').unbind('click').click(function() {
        localStorage.UserId = 0;
        $.mobile.changePage('#loginPage');
    });

    var dataToSend = { UserId: localStorage.UserId };
    $.ajax({
        url: WebServiceURL + "/GetSummary",
        dataType: "json",
        type: "POST",
        data : JSON.stringify(dataToSend),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            var summary = JSON.parse(data.d);
            $('#numOfOrders').text(summary["numOfOrders"]);
            $('#onTheWay').text(summary["onTheWay"]);
            $('#totalExpenses').text(summary["totalExpenses"]);
            $('#openedCases').text(summary["openedCases"]);
        }
    });
}


//----------------------------------------------
// MY ORDERS
//----------------------------------------------
$(document).on("pagebeforeshow", "#myOrdersPage", function (event) {
    wireEventsMyOrdersPage();
});


function wireEventsMyOrdersPage() {


    var getProductFilter = {
        OrderBy: localStorage.OrderBy,
        StatusFilter: "ALL",
        UserId: localStorage.UserId
    };
    $.ajax({
        url: WebServiceURL + "/GetUserProductsById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(getProductFilter),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

            $('#ordersListView').children().remove('li');

            data.d.forEach(function (element) {
                var listItem = {
                    Id: element["Id"],
                    Name: element["Name"],
                    Price: element["Price"],
                    OrderDate: element["OrderDate"],
                    TrackingNum: element["TrackingNumber"],
                    Status: element["Status"],
                    PicUrl: element["PicUrl"],
                    DaysRemain: element["DaysRemainToCase"]
                };
                var itemContent =
                    "<a href='#'>" +
                        "<img src='" + listItem['PicUrl'] + "' alt='Images/package-icon.png'/>" +
                        "<h2>" + listItem['Name'] + "</h2>" +
                        "<p>" + listItem['Price'] + " NIS " +
                        "<br/>" + listItem['OrderDate'] +
                        " Days left: " + listItem['DaysRemain'] + "</p>" +
            "</a>";

                $('#ordersListView').append('<li onclick="productListOnClick(' + listItem['Id'] + ')" class="ui-listview ui-listview-inset ui-corner-all ui-shadow">' + itemContent + '</li>').listview('refresh');

            });
        }
    });

}



//----------------------------------------------
// WAIT LIST PAGE
//----------------------------------------------
$(document).on("pagebeforeshow", "#waitListPage", function (event) {

    var getProductFilter = {
        OrderBy: localStorage.OrderBy,
        StatusFilter: "OnTheWay",
        UserId: localStorage.UserId
    };
    $.ajax({
        url: WebServiceURL + "/GetUserProductsById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(getProductFilter),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

            $('#waitListView').children().remove('li');

            data.d.forEach(function (element) {
                var listItem = {
                    Id: element["Id"],
                    Name: element["Name"],
                    Price: element["Price"],
                    OrderDate: element["OrderDate"],
                    TrackingNum: element["TrackingNumber"],
                    Status: element["Status"],
                    PicUrl: element["PicUrl"],
                    DaysRemain: element["DaysRemainToCase"]
                };
                var itemContent =
                    "<a href='#'>" +
                        "<img src='" + listItem['PicUrl'] + "' alt='Images/package-icon.png'/>" +
                        "<h2>" + listItem['Name'] + "</h2>" +
                        "<p>" + listItem['Price'] + " NIS " +
                        "<br/>" + listItem['OrderDate'] +
                        " Days left: " + listItem['DaysRemain'] + "</p>" +
            "</a>";

                $('#waitListView').append('<li onclick="productListOnClick(' + listItem['Id'] + ')" class="ui-listview ui-listview-inset ui-corner-all ui-shadow">' + itemContent + '</li>').listview('refresh');

            });
        }
    });

});




//----------------------------------------------
// PRODUCT DETAILS PAGE
//----------------------------------------------
$(document).on("pagebeforeshow", "#productDetailsPage", function (event) {

    //    alert("Current product id is " + productIdStore);
    var x = { Id: localStorage.productIdStore };
    $.ajax({
        url: WebServiceURL + "/GetProductById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(x),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

            var element = data.d;
            $('#lblProductName').text(element["Name"]);
            $('#lblPrice').text(element["Price"]);
            $('#lblOrderDate').text(element["OrderDate"]);
            $('#lblTrackingNumber').text(element["TrackingNumber"]);
            $('#lblStatus').text(element["Status"]);
            $('#lblUrl').text(element["Url"]);
            $('#lblTrackingInfo').text(element["TrackingInfo"]);
            $('#lblDaysToCase').text(element["DaysRemainToCase"]);

            document.getElementById("lblUrl").href = "Http://" + element["Url"];
            //document.getElementById("lblUrl").href.abs = "external";

            document.getElementById("prodImage").src = element["PicUrl"];

            //    $('#prodImage').src(element["picUrl"]);
            //     $('#xxxxx').text(element["xxxx"]);

        }
    });


    //Product Details buttons events
    $('#btnDeleteOrder').unbind('click').click(function () {

        var idToDelete = localStorage.productIdStore;
        DeleteProductById(idToDelete);
    });

    $('#btnEditOrder').unbind('click').click(function () {

        $.mobile.changePage('#editOrderPage');
        CustomAlert("Transfered from Edit Button");

    });


    $('#btnMarkArrived').unbind('click').click(function () {

        MarkArrived(localStorage.productIdStore);

    });


});


//----------------------------------------------
// ADD PRODUCT / NEW ORDER PAGE
//----------------------------------------------
$(document).on("pageshow", "#newOrderPage", function (event) {


    //set the current date
    var today = new Date();
    var now = today.getDate() + "/" + (today.getMonth() + 1) + "/" + today.getFullYear();
    $('#txtOrderDate').val(now);

    $('#selStatus').val("OnTheWay").selectmenu('refresh');

    $('#imgPG').unbind('click').click(function () {
        Camera_Open();
    });



    $('#btnSaveOrder').unbind('click').click(function () {

        if (!ValidateAddProduct()) //add product validation
            return;

        var newOrder = {
            Name: $('#txtProductName').val(),
            Price: $('#txtPrice').val(),
            OrderDate: $('#txtOrderDate').val(),
            DaysToCase: $('#txtDaysToCase').val(),
            Status: $('#selStatus').val(),
            TrackingNumber: $('#txtTrackingNumber').val(),
            Url: $('#txtUrl').val(),
            PicUrl: imageServerRoot + lastImageFilename,
            UserId: localStorage.UserId
    };


        if (imageTaken) //after camera success
        {
            UploadImage();
            AddProduct(newOrder, false);
        }
        else {
            newOrder.PicUrl = serverRoot + "images/package-icon.png";
            AddProduct(newOrder, true);
        }


    });
});




//----------------------------------------------
// EDIT ORDER
//----------------------------------------------
$(document).on("pagebeforeshow", "#editOrderPage", function (event) {

    var x = { Id: localStorage.productIdStore };
    $.ajax({
        url: WebServiceURL + "/GetProductById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(x),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            var element = data.d;

            $('#txtProductName_editPage').val(element["Name"]);
            $('#txtPrice_editPage').val(element["Price"]);
            $('#txtTrackingNumber_editPage').val(element["TrackingNumber"]);
            $('#txtOrderDate_editPage').val(element["OrderDate"]);
            $('#txtDaysToCase_editPage').val(element["DaysToCase"]);
            $('#txtUrl_editPage').val(element["Url"]);
            $('#selStatus_editPage').val(element["Status"]).selectmenu('refresh');
            document.getElementById("prodImage_editPage").src = element["PicUrl"];
        }
    });


    //event for update button

    $('#btnUpdateOrder').unbind('click').click(function () {

        if (!ValidateEditProduct()) //add product validation
            return;

        var updatedProduct = {

            Id: localStorage.productIdStore.toString(),
            Name: $('#txtProductName_editPage').val(),
            Price: $('#txtPrice_editPage').val(),
            OrderDate: $('#txtOrderDate_editPage').val(),
            DaysToCase: $('#txtDaysToCase_editPage').val(),
            Status: $('#selStatus_editPage').val(),
            TrackingNumber: $('#txtTrackingNumber_editPage').val(),
            Url: $('#txtUrl_editPage').val(),
            PicUrl: document.getElementById("prodImage_editPage").src
        };

        UpdateProduct(updatedProduct);

    });
});



//----------------------------------------------
// SETTINGS
//----------------------------------------------

$(document).on("pagebeforeshow", "#settingsPage", function (event) {
    wireEventsSettingsPage();
});

function wireEventsSettingsPage() {

    //Set controls values to match localStorage
    //$('#selTrackNotification').val(localStorage.Track).slider('refresh');

    LoadCaseReminder(); //load global case setting
    LoadTrackNotificationById(localStorage.UserId);
    $('#orderBy').val(localStorage.OrderBy).selectmenu('refresh');


    // Set local storage to match controls on change
    $('#caseReminder').change(function () {
        var caseReminder = $('#caseReminder').val();
        SetDaysToRemind(caseReminder);
    });

    $('#orderBy').change(function () {
        localStorage.OrderBy = $('#orderBy').val();
    });

    $('#selTrackNotification').change(function () {
        SetTrackNotificationById(localStorage.UserId, $('#selTrackNotification').val());
    });

    
    $('#btnClearDatabase').unbind('click').click(function () {

        if (confirm("Are you sure??") == true) {
            $.ajax(
           {
               url: WebServiceURL + "/DeleteAllProducts",
               dataType: "json",
               type: "POST",
               contentType: "application/json; charset=utf-8",
               error: function (jqXHR, exception) {
                   alert(formatErrorMessage(jqXHR, exception));
               },
               success: function (data) {
                   alert("success delete");
                   $.mobile.changePage('#myOrdersPage');
               }
           });

        }

    });


    $('#btnDailyDisputeCheck').unbind('click').click(function () {
        $.ajax(
        {
            url: WebServiceURL + "/DailyDisputeCheck",
            dataType: "json",
            type: "POST",
            contentType: "application/json; charset=utf-8",
            error: function (jqXHR, exception) {
                alert(formatErrorMessage(jqXHR, exception));
            },
            success: function (data) {
                alert("Daily Dispute Check done!");
            }
        });
    });



} //end of settings wireEvents




//FUNCTIONS

function MarkArrived(productId) {

    var dataToSend = { Id: productId };

    $.ajax(
    {
        url: WebServiceURL + "/MarkArrived",  // set web method path and function name
        dataType: "json",
        type: "POST", //use only POST!
        data: JSON.stringify(dataToSend),  // set the data to transfer to ajax, needs to be json formated and must have same var Names
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            $('#lblStatus').text("Arrived");
            alert("Product was marked as arrived!");
        }
    });
}


function DeleteProductById(idToDelete) {
    var dataToSend = { Id: idToDelete };
    $.ajax(
    {
        url: WebServiceURL + "/DeleteProductById", // set web method path and function name
        dataType: "json",
        type: "POST", //use only POST!
        data: JSON.stringify(dataToSend), // set the data to transfer to ajax, needs to be json formated and must have same var Names
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            $.mobile.changePage('#myOrdersPage');
            CustomAlert("Transfered from delete by id");

        }
    });
}

function UpdateProduct(updatedProduct) {
    $.ajax(
    {
        url: WebServiceURL + "/UpdateProduct",  // set web method path and function name
        dataType: "json",
        type: "POST", //use only POST!
        data: JSON.stringify(updatedProduct),  // set the data to transfer to ajax, needs to be json formated and must have same var Names
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

            alert("Update product");
            $.mobile.changePage('#myOrdersPage');

            CustomAlert("Transfered from Update");
        }
    });

}


function AddProduct(newOrder2, movePage) {
    $.ajax(
    {
        url: WebServiceURL + "/AddProduct",  // set web method path and function name
        dataType: "json",
        type: "POST", //use only POST!
        data: JSON.stringify(newOrder2),  // set the data to transfer to ajax, needs to be json formated and must have same var Names
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {

            CustomAlert("Transfered from Add");

            if (movePage)
                $.mobile.changePage('#myOrdersPage');

            ClearAddProductForm();


        }
    });
}


function productListOnClick(id) { // when clicking on Product list item
    localStorage.productIdStore = id;
    $.mobile.changePage('#productDetailsPage');
    CustomAlert("Transfered from ProductClick");
}

function formatErrorMessage(jqXHR, exception) {
    if (jqXHR.status === 0)
    { return ('Not connected.\nPlease verify your network connection.'); }
    else if (jqXHR.status == 404)
    { return ('The requested page not found. [404]'); }
    else if (jqXHR.status == 500) { return ('Internal Server Error [500].'); }
    else if (exception === 'parsererror') { return ('Requested JSON parse failed.'); }
    else if (exception === 'timeout') { return ('Time out error.'); }
    else if (exception === 'abort') { return ('Ajax request aborted.'); }
    else { return ('Uncaught Error.\n' + jqXHR.responseText); }
}


function onFailCamera(message) {
    alert('Failed because: ' + message);
}


function Camera_Open(parameters) {
    navigator.camera.getPicture(onPhotoUriSuccess, onFailCamera, {
        quality: 75,
        targetWidth: 1000,
        targetHeight: 1000,
        destinationType: Camera.DestinationType.FILE_URI,
        sourceType: Camera.PictureSourceType.CAMERA
    });

}


function onPhotoUriSuccess(imageUriToUpload) {

    var image = $('#imgPG');
    image.attr('src', imageUriToUpload);

    imageSource = imageUriToUpload;
    imageTaken = true;
    lastImageFilename = imageSource.substr(imageSource.lastIndexOf('/') + 1);
}


function UploadImage() {

    var url = encodeURI(imageServerRoot + "/ReturnValue.ashx");
    var params = new Object();
    var options = new FileUploadOptions();

    options.fileKey = "file"; //depends on the api
    var newFileName = imageSource.substring(imageSource.lastIndexOf('/') + 1, imageSource.lastIndexOf('.'));

    options.fileName = newFileName;
    options.mimeType = "image/jpeg";
    options.params = params;

    options.chunkedMode = true; //this is important to send both data and files
    var ft = new FileTransfer();
    ft.upload(imageSource, url, successFileTransfer, errorFileTransfer, options);
    imageTaken = false;
}

function successFileTransfer(r) {
    alert("file upload succeed");
    //alert("Code = " + r.responseCode);
    //alert("Response = " + r.response);
    //alert("Response =" + r.response);
    //alert("Sent = " + r.bytesSent);
    $.mobile.changePage('#myOrdersPage');
}

function errorFileTransfer(error) {
    alert("file upload failed");
    alert("An error has occurred: Code = " + error.code);
    alert("upload error source " + error.source);
    alert("upload error target " + error.target);
}


function CustomAlert(msg) {
    // alert(msg);
}


function SetDaysToRemind(value) {
    var dataToSend = { days: value };
    $.ajax({
        url: WebServiceURL + "/SetDaysToRemind",
        dataType: "json",
        data: JSON.stringify(dataToSend),
        type: "POST",
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
        }
    });
}


function LoadCaseReminder() {
    $.ajax({
        url: WebServiceURL + "/GetDaysToRemind",
        dataType: "json",
        type: "POST",
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            $('#caseReminder').val(data.d).selectmenu('refresh');
        }
    });
}


function SetTrackNotificationById(id, trackValue) {

    var dataToSend = {
        UserId: id,
        Track: trackValue
    };
    $.ajax(
    {
        url: WebServiceURL + "/SetTrackNotificationById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(dataToSend),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            alert("success Update Track");
        }
    });
}


function LoadTrackNotificationById(id) {
    var dataToSend = { UserId: id };
    $.ajax({
        url: WebServiceURL + "/GetTrackNotificationById",
        dataType: "json",
        type: "POST",
        data: JSON.stringify(dataToSend),
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            $('#selTrackNotification').val(data.d).selectmenu('refresh');
        }
    });
}


function ValidateAddProduct() {

    if ($('#txtProductName').val().length == 0) {
        alert("You must enter a product name!");
        return false;
    }

    if (isNaN(parseInt($('#txtPrice').val())) || parseInt($('#txtPrice').val()) <= 0) {
        alert("You must enter a valid price!");
        return false;
    }

    if (isNaN(parseInt($('#txtDaysToCase').val())) || parseInt($('#txtDaysToCase').val()) <= 0) {
        alert("You must enter a valid number of days!");
        return false;
    }

    return true; //validation success
}

function ValidateEditProduct() {

    if ($('#txtProductName_editPage').val().length == 0) {
        alert("You must enter a product name!");
        return false;
    }

    if (isNaN(parseInt($('#txtPrice_editPage').val())) || parseInt($('#txtPrice').val()) <= 0) {
        alert("You must enter a valid price!");
        return false;
    }

    if (isNaN(parseInt($('#txtDaysToCase_editPage').val())) || parseInt($('#txtDaysToCase_editPage').val()) <= 0) {
        alert("You must enter a valid number of days!");
        return false;
    }

    return true; //validation success
}

function ClearAddProductForm() {
    var today = new Date();
    var now = today.getDate() + "/" + (today.getMonth() + 1) + "/" + today.getFullYear();

    $('#txtProductName').val("");
    $('#txtPrice').val("");
    $('#txtTrackingNumber').val("");
    $('#txtOrderDate').val(now);
    $('#txtDaysToCase').val(45);
    $('#txtUrl').val("");
    $('#selStatus').val("OnTheWay");
}

function CheckLogin() {
    if (localStorage.UserId == null || localStorage.UserId == 0) {
        $.mobile.changePage('#loginPage');
    }

}


function GetUserIdByEmail(value) {
    var email = { email: value };
    $.ajax({
        url: WebServiceURL + "/GetUserIdByEmail",
        dataType: "json",
        data: JSON.stringify(email),
        type: "POST",
        contentType: "application/json; charset=utf-8",
        error: function (jqXHR, exception) {
            alert(JSON.stringify(jqXHR)); //extended error
            // alert(formatErrorMessage(jqXHR, exception));
        },
        success: function (data) {
            localStorage.UserId = data.d;
            $.mobile.changePage('#homePage');
        }
    });
}

//-------- TODO LIST -------------
// users
// check dispute reminder application reset
// be happy for the rest of your life (:






