
use cegroup6Db
Set DateFormat dmy
GO

CREATE TABLE [dbo].[User] (
    [Id]    INT           IDENTITY (1, 1) NOT NULL,
    [Email] NVARCHAR (50) NOT NULL,
    [Track] BIT           DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

CREATE TABLE [dbo].[Product] (
    [Id]             INT            IDENTITY (1, 1) NOT NULL,
    [Name]           NVARCHAR (50)  NOT NULL,
    [Price]          FLOAT (53)     NOT NULL,
    [OrderDate]      DATETIME       NOT NULL,
    [DaysToCase]     INT            NOT NULL,
    [Status]         NVARCHAR (50)  NULL,
    [TrackingInfo]   NVARCHAR (500) NULL,
    [TrackingNumber] NVARCHAR (50)  NULL,
    [Url]            NVARCHAR (200) NULL,
    [PicUrl]         NVARCHAR (200) NULL,
    [UserId]         INT            DEFAULT ((1)) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

insert into [User] values('maort22@gmail.com');
insert into [User] values('shai.patael@gmail.com');
insert into [User] values('yanayh90@gmail.com');


insert into Product values('Case',0.42,'01/01/2016',45,'OnTheWay',null,null,'www.google.com','http://cdn-wpmsa.defymedia.com/wp-content/uploads/sites/3/2014/10/Pokemon-Phone-Case.jpg',1)
insert into Product values('Ipad',120.42,'11/02/2016',60,'OnTheWay',null,null,'www.google.com','http://cdn2.pcadvisor.co.uk/cmsdata/features/3407201/ipad-mini-4-uk.jpg',1)
insert into Product values('T-Shirt',12.42,'07/03/2016',39,'OnTheWay',null,null,'www.google.com','http://tshirts.co.za/image/cache/data/Round-black-tshirt-500x500.jpg',1)
insert into Product values('Camera',105,'02/04/2016',45,'OnTheWay',null,null,'www.google.com','http://www.camera4less.co.il/images/SJ400.jpg',2)
insert into Product values('Arduino',2.42,'09/05/2016',40,'OnTheWay',null,null,'www.google.com','https://upload.wikimedia.org/wikipedia/commons/3/38/Arduino_Uno_-_R3.jpg',2)
insert into Product values('Selfie stick',1.42,'11/06/2016',79,'OnTheWay',null,null,'www.google.com','http://selfiestickcentral.com/wp-content/uploads/2015/01/selfie-stick.jpg',3)
insert into Product values('Bluetooth Headphone',25.42,'21/06/2016',15,'OnTheWay',null,null,'www.google.com','http://www.hensonaudio.com/image/cache/data/Henson%20BTH033/Henson%20Audio%20BTH033%20Bluetooth%20Headphones-800x800.jpg',2)
insert into Product values('Shoes',72.42,'15/06/2016',20,'OnTheWay',null,null,'www.google.com','https://static.pexels.com/photos/19090/pexels-photo.jpg',3)

GO

CREATE PROCEDURE Get_User_Id @Email NVARCHAR(50), @UserId Int OUTPUT
AS
	IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[User] WHERE Email = @Email)
	BEGIN
		INSERT INTO [dbo].[User] VALUES(@Email,1)
		SET @UserId = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		SELECT @UserId = Id FROM [dbo].[User] WHERE Email = @Email
	END
RETURN



--CREATE TABLE [dbo].[User]
--(
--	[Id] INT NOT NULL PRIMARY KEY, 
--    [Email] NVARCHAR(50) NOT NULL, 
--    [Track] BIT NOT NULL DEFAULT 1
--)
