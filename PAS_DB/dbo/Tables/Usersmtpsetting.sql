CREATE TABLE [dbo].[Usersmtpsetting] (
    [smtpsettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [emailtype]     INT           DEFAULT ((1)) NULL,
    [verifyemail]   BIT           DEFAULT ((0)) NULL,
    [EmployeeId]    BIGINT        NULL,
    [smtpserver]    VARCHAR (256) NULL,
    [emailpassword] VARCHAR (556) NULL,
    [portno]        INT           NULL,
    [CreatedDate]   DATETIME2 (7) DEFAULT (getdate()) NULL,
    [UpdatedDate]   DATETIME2 (7) DEFAULT (getdate()) NULL
);

