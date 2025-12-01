CREATE TABLE [dbo].[CustomerTicket] (
    [CustomerTicketId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TicketID]         VARCHAR (MAX)  NULL,
    [Name]             VARCHAR (200)  NULL,
    [FromEmail]        VARCHAR (4000) NULL,
    [ToEmail]          VARCHAR (4000) NULL,
    [DepartmentId]     INT            NOT NULL,
    [PriorityId]       INT            NOT NULL,
    [Subject]          VARCHAR (MAX)  NULL,
    [EmailBody]        VARCHAR (MAX)  NULL,
    [AttachmentId]     BIGINT         NULL,
    [MasterCompanyId]  INT            NULL,
    [AssignTo]         BIGINT         NOT NULL,
    [ReportedBy]       VARCHAR (256)  NULL,
    [CreatedBy]        VARCHAR (256)  NULL,
    [UpdatedBy]        VARCHAR (256)  NULL,
    [CreatedDate]      DATETIME2 (7)  NULL,
    [UpdatedDate]      DATETIME2 (7)  NULL,
    [IsActive]         BIT            NULL,
    [IsDeleted]        BIT            NULL,
    [StatusId]         INT            NOT NULL,
    [EmployeeId]       BIGINT         NOT NULL,
    [TicketTypeId]     BIGINT         NULL
);


GO
CREATE TRIGGER [dbo].[Trg_CustomerTicketAudit] ON [dbo].[CustomerTicket]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[CustomerTicketAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END