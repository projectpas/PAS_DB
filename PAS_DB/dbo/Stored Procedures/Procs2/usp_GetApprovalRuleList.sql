/*************************************************************           
 ** File:   [usp_GetApprovalRuleList]           
 ** Author:  Amit Ghediya
 ** Description: 
 ** Purpose:         
 ** Date:        
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/09/2023  Amit Ghediya		Update UserRole select based on ApprovalRule.  
	2    05/02/2025  Divyesh Kathiriya	Update CreatedDate and UpdateDate based on Employee time zone.
     
exec [dbo].[usp_GetApprovalRuleList] @MasterCompanyId=1,@TaskID=2,@IsDeleted=0,@Status=N'Active',@StatusID=1,@EmployeeId=93
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetApprovalRuleList]

@MasterCompanyId int = null,
@TaskID BIGINT,
@IsDeleted bit = null,
@Status varchar(50)=null,
@StatusID bit,
@EmployeeId BIGINT

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				DECLARE @EmpLegalEntiyId BIGINT = 0;
				DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
				SELECT @EmpLegalEntiyId = LegalEntityId FROM DBO.Employee WHERE EmployeeId = @EmployeeId;
				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

					IF(@Status = 'All')
					BEGIN
						SELECT DISTINCT AP.ApprovalRuleId,
								APT.[Name] AS TaskName,
								ARN.RuleNo AS RuleNo,
								AMT.[Name] AS Amount,
								AP.[Value],
								AP.LowerValue,
								AP.UpperValue,
								AP.Memo,
								EMP.FirstName + ' ' + EMP.LastName AS Approver,
								--AP.CreatedDate,
								CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(AP.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(AP.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
								ELSE (CAST(AP.CreatedDate AS DATE)) END CreatedDate,
								AP.CreatedBy,
								AP.UpdatedBy,
								--AP.UpdatedDate,
								CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(AP.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(AP.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
								ELSE (CAST(AP.UpdatedDate AS DATE)) END UpdatedDate,
								AP.IsActive,
								AP.IsDeleted,
								--MSD.LastMSLevel,
								--AllMSlevels = (SELECT AllMSlevels FROM DBO.GetAllMSLevelString(AP.ManagementStructureId))
								'' AS LastMSLevel,
								'' AS AllMSlevels,
								USR.[Name] AS UserRole
								from ApprovalRule AP WITH (NOLOCK)
						INNER JOIN ApprovalTask APT  WITH (NOLOCK) ON AP.ApprovalTaskId = APT.ApprovalTaskId
						INNER JOIN Employee EMP  WITH (NOLOCK) ON AP.ApproverId = EMP.EmployeeId
						LEFT JOIN ApprovalRuleNo ARN  WITH (NOLOCK) ON AP.RuleNumberId = ARN.ApprovalRuleNoId
						LEFT JOIN ApprovalAmount AMT  WITH (NOLOCK) ON AP.AmountId = AMT.ApprovalAmountId
						--INNER JOIN dbo.ManagementStructureDetails MSD WITH (NOLOCK) ON MSD.EntityMSID = AP.ManagementStructureId
						LEFT JOIN Approver APR WITH (NOLOCK) ON AP.ApproverId = APR.ApproverId
						INNER JOIN UserRole USR WITH (NOLOCK) ON AP.RoleId = USR.Id
						WHERE AP.ApprovalTaskId = @TaskID AND AP.MasterCompanyId = @MasterCompanyId AND AP.IsDeleted = @IsDeleted ORDER BY AP.ApprovalRuleId DESC;
					END
					ELSE
					BEGIN
						SELECT DISTINCT AP.ApprovalRuleId,
								APT.[Name] AS TaskName,
								ARN.RuleNo AS RuleNo,
								AMT.[Name] AS Amount,
								AP.[Value],
								AP.LowerValue,
								AP.UpperValue,
								AP.Memo,
								EMP.FirstName + ' ' + EMP.LastName AS Approver,
								--AP.CreatedDate,							
								CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(AP.CreatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(AP.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
								ELSE (CAST(AP.CreatedDate AS DATE)) END CreatedDate,
								AP.CreatedBy,
								AP.UpdatedBy,
								--AP.UpdatedDate,								
								CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
								CASE WHEN CAST(AP.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(AP.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATE)) END 
								ELSE (CAST(AP.UpdatedDate AS DATE)) END UpdatedDate,
								AP.IsActive,
								AP.IsDeleted,
								--MSD.LastMSLevel,
								--AllMSlevels = (SELECT AllMSlevels FROM DBO.GetAllMSLevelString(AP.ManagementStructureId))
								'' AS LastMSLevel,
								'' AS AllMSlevels,
								USR.[Name] AS UserRole
								from ApprovalRule AP WITH (NOLOCK)
						INNER JOIN ApprovalTask APT  WITH (NOLOCK) ON AP.ApprovalTaskId = APT.ApprovalTaskId
						INNER JOIN Employee EMP  WITH (NOLOCK) ON AP.ApproverId = EMP.EmployeeId
						LEFT JOIN ApprovalRuleNo ARN  WITH (NOLOCK) ON AP.RuleNumberId = ARN.ApprovalRuleNoId
						LEFT JOIN ApprovalAmount AMT  WITH (NOLOCK) ON AP.AmountId = AMT.ApprovalAmountId
						--INNER JOIN dbo.ManagementStructureDetails MSD WITH (NOLOCK) ON MSD.EntityMSID = AP.ManagementStructureId
						LEFT JOIN Approver APR WITH (NOLOCK) ON AP.ApproverId = APR.ApproverId
						INNER JOIN UserRole USR WITH (NOLOCK) ON AP.RoleId = USR.Id
						WHERE AP.ApprovalTaskId = @TaskID AND AP.MasterCompanyId = @MasterCompanyId AND AP.IsDeleted = @IsDeleted AND AP.IsActive = @StatusID ORDER BY AP.ApprovalRuleId DESC;
					END
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_GetApprovalRuleList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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