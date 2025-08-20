/*************************************************************                 
 ** File:   [GetJournalBatchDetailsViewById]      
 ** Author:  Satish Gohil      
 ** Description: This stored procedure is used get Batch Details By Id      
 ** Purpose:               
 ** Date:   03/08/2023            
                
 ** PARAMETERS: @JournalBatchHeaderId bigint      
               
 ** RETURN VALUE:                 
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change Description                  
 ** --   --------     -------  --------------------------------                
    1    03/08/2023  Satish Gohil   AccountingPeriodId and AccountingPeriod Field Added      
    2    18/09/2023  Bhargav Saliya  Added Fields PostedDate and Status 
	3	 19/10/2023	 Nainshi Joshi    Added Field PostedBy
	4	 30/10/2023	 Ayesha Sultana   Batch name retriving issue fix
	5	 09/04/2025	 Ekta Chandegra	  Convert date using dbo.ConvertUTCtoLocal
	6	 04/08/2024  AMIT GHEDIYA	  Added Field ReferenceNumber.
	7	 19/08/2025  BHARGAV SALIYA	  Added Case for [JournalTypeName].
************************************************************************/    
--[GetJournalBatchDetailsViewById]  826    
CREATE        PROCEDURE [dbo].[GetJournalBatchDetailsViewById]      
@JournalBatchHeaderId bigint,
@EmployeeId bigint
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
	 BEGIN TRY    
	 DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
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
					E.EmployeeId = @EmployeeId;

		  SELECT JBH.JournalBatchHeaderId,
				  JBD.JournalBatchDetailId,
				  JBH.Module,
				  JBH.BatchName,
				  ISNULL(JBD.DebitAmount,0) as DebitAmount,  
				  ISNULL(JBD.CreditAmount,0) as CreditAmount,
				  JBD.JournalTypeNumber,
				  (Cast(DBO.ConvertUTCtoLocal(JBD.EntryDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as EntryDate,
				  CASE WHEN ISNULL(JBD.IsReversedJE, 0) = 1 THEN UPPER(JBD.[JournalTypeName]) + ' (REVERSED)' ELSE UPPER(JBD.[JournalTypeName]) END  AS [JournalTypeName],
				  --JBD.JournalTypeName,  
				  JT.JournalTypeCode,
				  JBD.StatusId,
				  (Cast(DBO.ConvertUTCtoLocal(JBH.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
				  (Cast(DBO.ConvertUTCtoLocal(JBH.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate,
				  JBD.CreatedBy,
				  JBD.UpdatedBy,      
				  JBD.AccountingPeriodId,
				  JBD.AccountingPeriod,
				  (Cast(DBO.ConvertUTCtoLocal(JBD.PostedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as PostedDate,
				  JBD.PostedBy,
				  BS.Name AS [Status],
				 (SELECT TOP 1 CBD.[ReferenceNumber] FROM [dbo].[CommonBatchDetails] CBD WITH(NOLOCK) WHERE CBD.[JournalBatchDetailId] = JBD.[JournalBatchDetailId]) AS ReferenceNumber
		  FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)      
		  INNER JOIN BatchDetails JBD WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId       
		  LEFT JOIN BatchStatus BS WITH(NOLOCK) ON JBD.StatusId = BS.ID      
		  LEFT JOIN JournalType JT WITH(NOLOCK) ON JBD.JournalTypeId = JT.ID      

		  --Inner JOIN CommonBatchDetails CJBD WITH(NOLOCK) ON JBD.JournalBatchDetailId=CJBD.JournalBatchDetailId    
  
		  WHERE JBH.JournalBatchHeaderId =@JournalBatchHeaderId and JBD.IsDeleted=0 ORDER BY JournalBatchDetailId DESC;     
  
    END TRY      
 BEGIN CATCH            
  IF @@trancount > 0      
   PRINT 'ROLLBACK'      
   ROLLBACK TRAN;      
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
            , @AdhocComments     VARCHAR(150)    = 'GetJournalBatchDetailsViewById'       
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@JournalBatchHeaderId, '') + ''      
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