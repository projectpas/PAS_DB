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
	2    17/01/2025  Ekta Chandegra     Retrieve Employee name and email
	3    27/01/2025  Bhargav Saliya     Convert Date as per time zone
	4    11/21/2025  Bhargav Saliya     Get TicketType
	5    12/09/2025  Bhargav Saliya     Revert the UTC Date Conversation


exec [dbo].[GetCustomerTicketById] @CustomerTicketId = 4

************************************************************************/
CREATE     PROCEDURE [dbo].[GetCustomerTicketById]
@CustomerTicketId BIGINT = NULL,
@EmployeeId bigint = 0
AS
BEGIN 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON

		--DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		--SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
		--	LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		--	LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		--	LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		--WHERE E.EmployeeId = @EmployeeId; 

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
				--CASE WHEN CAST(CTR.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CTR.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
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
				--CASE WHEN CAST(CT.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CT.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME))END CreatedDate,
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
				EMP.FirstName +' '+EMP.LastName AS AssignToName, 
				EMP.Email AS AssignToEmail, 
				CT.AttachmentId,
				tt.Description,
				tt.TicketTypeId
			FROM
			[dbo].[CustomerTicket] CT WITH (NOLOCK)
			LEFT JOIN [dbo].[SupportDepartment] SD WITH (NOLOCK) ON CT.DepartmentId = SD.DepartmentId
			LEFT JOIN [dbo].[TicketStatus] TS WITH (NOLOCK) ON CT.StatusId = TS.TicketStatusId
			LEFT JOIN [dbo].[TicketPriority] TP WITH (NOLOCK) ON CT.PriorityId = TP.PriorityId
			LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON CT.AssignTo = EMP.EmployeeId
			LEFT JOIN [dbo].[TicketType] tt WITH (NOLOCK) ON CT.TicketTypeId = tt.TicketTypeId
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