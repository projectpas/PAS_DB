/*************************************************************           
 ** File:   [GetCustomerTicketById]         
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used GetCustomerTicketById
 ** Purpose:         
 ** Date:   11/11/2024     
         
 ** PARAMETERS:    @CustomerTicketId   bigint     
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/11/2024  Ekta Chandegra     Created


exec [dbo].[GetCustomerTicketById] @CustomerTicketId = 2

************************************************************************/
CREATE     PROCEDURE [dbo].[GetCustomerTicketById]
@CustomerTicketId BIGINT = NULL
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN

			SELECT 
				CTR.TicketResponseId,
				CTR.CustomerTicketId,
				CTR.ResponseById,
				CTR.ResponseByName,
				(ISNULL(CTR.ResponseBody,'')) AS ResponseBody,
				CTR.CreatedBy,
				CTR.UpdatedBy,
				CTR.CreatedDate,
				CTR.UpdatedDate,
				CTR.IsActive,
				CTR.IsDeleted,
				CTR.MasterCompanyId,
				CTR.AttachmentId
			FROM 
			[dbo].[CustomerTicketResponse] CTR WITH (NOLOCK)
			LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON CTR.ResponseById = EMP.EmployeeId
			LEFT JOIN [dbo].[TicketStatus] TS WITH (NOLOCK) ON CTR.StatusId = TS.TicketStatusId
			WHERE CTR.CustomerTicketId =  @CustomerTicketId
			AND ISNULL(CTR.IsActive,0) = 1
			AND ISNULL(CTR.IsDeleted,0) = 0
			ORDER BY CTR.TicketResponseId DESC


			SELECT 
				CTR.TicketResponseId,
				CTR.CustomerTicketId,
				AD.AttachmentDetailId,
				AD.AttachmentId,
				AD.FileName,
				AD.Description,
				AD.Link,
				AD.FileType,
				AD.FileSize,
				AD.IsActive,
				AD.IsDeleted,
				AD.CreatedBy,
				AD.CreatedDate,
				AD.UpdatedBy,
				AD.UpdatedDate
			FROM [dbo].[CustomerTicketResponse] CTR WITH (NOLOCK)
			LEFT JOIN [dbo].AttachmentDetails AD WITH (NOLOCK) ON CTR.AttachmentId = AD.AttachmentId
			WHERE CTR.CustomerTicketId = @CustomerTicketId
			AND ISNULL(AD.IsActive,0) = 1
			AND ISNULL(AD.IsDeleted,0) = 0


			SELECT
				CT.CustomerTicketId,
				(ISNULL(CT.TicketID,'')) AS TicketID,
				CT.Name AS 'UserName',
				(ISNULL(CT.Subject,'')) AS Subject,
				(ISNULL(CT.EmailBody,'')) AS EmailBody,
				CT.FromEmail,
				CT.CreatedBy,
				CT.CreatedDate,
				CT.UpdatedBy,
				CT.UpdatedDate,
				CT.IsActive,
				CT.IsDeleted,
				CT.MasterCompanyId,
				SD.DepartmentId,
				SD.Description AS 'Department',
				TP.PriorityId,
				TP.Description AS 'Priority',
				TS.TicketStatusId,
				TS.Description AS 'Status',
				CT.ReportedBy,
				CT.AssignTo,
				CT.AttachmentId
			FROM
			[dbo].[CustomerTicket] CT WITH (NOLOCK)
			LEFT JOIN [dbo].[SupportDepartment] SD WITH (NOLOCK) ON CT.DepartmentId = SD.DepartmentId
			LEFT JOIN [dbo].[TicketStatus] TS WITH (NOLOCK) ON CT.StatusId = TS.TicketStatusId
			LEFT JOIN [dbo].[TicketPriority] TP WITH (NOLOCK) ON CT.PriorityId = TP.PriorityId
			LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON CT.AssignTo = EMP.EmployeeId
			WHERE CT.CustomerTicketId = @CustomerTicketId
			AND ISNULL(CT.IsActive,0) = 1
			AND ISNULL(CT.IsDeleted,0) = 0

			SELECT 
				CT.CustomerTicketId,
				AD.AttachmentDetailId,
				AD.AttachmentId,
				AD.FileName,
				AD.Description,
				AD.Link,
				AD.FileType,
				AD.FileSize,
				AD.IsActive,
				AD.IsDeleted,
				AD.CreatedBy,
				AD.CreatedDate,
				AD.UpdatedBy,
				AD.UpdatedDate
			FROM [dbo].[CustomerTicket] CT WITH (NOLOCK)
			LEFT JOIN [dbo].AttachmentDetails AD WITH (NOLOCK) ON CT.AttachmentId = AD.AttachmentId
			WHERE CT.CustomerTicketId = @CustomerTicketId
			AND ISNULL(AD.IsActive,0) = 1
			AND ISNULL(AD.IsDeleted,0) = 0

		END
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'GetCustomerTicketById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerTicketId, '') + ''''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END