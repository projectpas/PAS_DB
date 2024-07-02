/*************************************************************               
 ** File:   [GetJournalBatchHeaderById]               
 ** Author:  Shrey Chandegara    
 ** Description: This stored procedure is used to GetJournalBatchHeaderById    
 ** Purpose:             
 ** Date:   05/04/2023          
              
 ** PARAMETERS: @JournalBatchHeaderId     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------              
    1    08/10/2022  Shrey Chandegara     Created    
	2    05/09/2023  Amit Ghediya         Updated for add JE details with Batch detail
	3	 19/06/2023  Shrey Chandegara	  Updated for add JE Detail view like GLAccount,Credit,....
	3	 29/08/2023  Devendra Shekh		  added BatchStatus join for journal batchstatus
	5	 04/12/2023  Ayesha Sultana		  Date Time UTC convert
	6	 19/12/2023  Ayesha Sultana		  Date Time UTC convert - using LE from SSRS
	7	 10/01/2024  Moin Bloch		      Set TDate Format to MM-dd-yyy
    8	1st July 2024    Bhargav Saliya	  Set [EntryDate] Format to 'MM-dd-yyy'
-- EXEC GetMultipleJournalBatchHeaderById '1524,1523,1521,1520,1519,1518,1517,1516,1515,1495,1513,1467,1500',1 
************************************************************************/    
CREATE     PROCEDURE [dbo].[GetMultipleJournalBatchHeaderById]   
@JournalBatchHeaderId varchar(MAX)  = null,
@ManagementStructId varchar(max) = null
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    

   DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
   DECLARE @CurrentDateTime DATETIME='';

   SELECT @CurrntEmpTimeZoneDesc = TZ.[Description]    
   FROM [dbo].[LegalEntity] LE WITH (NOLOCK) 
		INNER JOIN [dbo].[TimeZone] TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
		INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId
		INNER JOIN [dbo].[EntityStructureSetup] ESS WITH(NOLOCK) ON ESS.Level1Id = MSL.ID
   WHERE ESS.EntityStructureId = @ManagementStructId

   SELECT @CurrentDateTime = GETDATE();

   SELECT   
   JBH.[JournalBatchHeaderId],  
   JBH.[BatchName],  
   JBH.[CurrentNumber],  
   --CAST(DBO.ConvertUTCtoLocal(JBH.[EntryDate], @CurrntEmpTimeZoneDesc) AS DATETIME) AS EntryDate,
   FORMAT(CAST(DBO.ConvertUTCtoLocal(JBH.[EntryDate], @CurrntEmpTimeZoneDesc) AS DATETIME),'MM/dd/yyyy') AS EntryDate, 
   CAST(DBO.ConvertUTCtoLocal(JBH.[PostDate], @CurrntEmpTimeZoneDesc) AS DATETIME) AS PostDate, 
   JBH.[AccountingPeriod],  
   JBH.[StatusId],  
   JBH.[StatusName],  
   JBH.[JournalTypeId],  
   JBH.[JournalTypeName],  
   JBH.[TotalDebit],  
   JBH.[TotalCredit],  
   JBH.[TotalBalance],  
   JBH.[MasterCompanyId],  
   JBH.[UpdatedBy],  
   JBD.[JournalBatchDetailId],  
   JBH.[Module],  
   ISNULL(JBD.[DebitAmount],0) AS DebitAmount,  
   ISNULL(JBD.[CreditAmount],0) AS CreditAmount,  
   JBD.[JournalTypeNumber] AS DJournalTypeNumber,  
   CAST(DBO.ConvertUTCtoLocal(JBD.[EntryDate], @CurrntEmpTimeZoneDesc) AS DATETIME) AS DEntryDate, -- JBD.[EntryDate] AS DEntryDate,  
   JBD.[JournalTypeName] AS DJournalTypeName,  
   JT.[JournalTypeCode],  
   CAST(DBO.ConvertUTCtoLocal(JBD.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,
   CAST(DBO.ConvertUTCtoLocal(JBD.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME) AS UpdatedDate, 
   JBD.[CreatedBy],  
   JBD.[UpdatedBy] AS DUpdatedBy,
   CD.CreditAmount AS Cr,
   CD.DebitAmount AS Dr,
   CD.GlAccountNumber + ' - ' + CD.GlAccountName AS GLAccount,
   --Cast(DBO.ConvertUTCtoLocal(CD.TransactionDate, @CurrntEmpTimeZoneDesc) as datetime) as TDate, 
   CASE WHEN UPPER(DM.DistributionCode) = UPPER('WOINVOICINGTAB') OR
             UPPER(DM.DistributionCode) = UPPER('SOINVOICE') OR
			 UPPER(DM.DistributionCode) = UPPER('EX-FeeBilling') OR			 
             UPPER(DM.DistributionCode) = UPPER('NonPOInvoice') OR 
             UPPER(DM.DistributionCode) = UPPER('ReconciliationRO') OR
			 UPPER(DM.DistributionCode) = UPPER('ReconciliationPO') 
        THEN FORMAT(CD.TransactionDate,'MM/dd/yyyy') 
		ELSE FORMAT(CAST(DBO.ConvertUTCtoLocal(CD.TransactionDate, @CurrntEmpTimeZoneDesc) AS DATETIME),'MM/dd/yyyy hh:mm:ss')
		END	AS TDate,   
   BS.[Name] AS 'BatchStatus',
   @CurrentDateTime AS PrintedDate
  FROM [dbo].[BatchHeader] JBH WITH(NOLOCK)  
  LEFT JOIN [dbo].[BatchDetails] JBD WITH(NOLOCK) ON JBD.JournalBatchHeaderId=JBH.JournalBatchHeaderId AND JBD.IsDeleted=0  
  LEFT JOIN [dbo].[JournalType] JT WITH(NOLOCK) ON JBD.JournalTypeId = JT.ID  
  LEFT JOIN [dbo].[CommonBatchDetails] CD WITH(NOLOCK) ON JBH.JournalBatchHeaderId = CD.JournalBatchHeaderId AND JBD.JournalBatchDetailId = CD.JournalBatchDetailId AND CD.IsDeleted = 0  
  LEFT JOIN [dbo].[BatchStatus] BS WITH(NOLOCK) ON JBD.StatusId = BS.ID  
  LEFT JOIN [dbo].[DistributionSetup] DS WITH(NOLOCK) ON CD.[DistributionSetupId] = DS.ID
  LEFT JOIN [dbo].[DistributionMaster] DM WITH(NOLOCK) ON DS.[DistributionMasterId] = DM.ID

  WHERE JBH.JournalBatchHeaderId IN (SELECT * FROM STRING_SPLIT(@JournalBatchHeaderId , ','))    
  --GROUP BY JBH.[JournalBatchHeaderId],JBH.[BatchName],JBH.[CurrentNumber],JBH.[EntryDate],JBH.[PostDate], JBH.[AccountingPeriod], JBH.[StatusId],  
  -- JBH.[StatusName],JBH.[JournalTypeId],JBH.[JournalTypeName], JBH.[TotalDebit],JBH.[TotalCredit], JBH.[TotalBalance],JBH.[MasterCompanyId],  
  -- JBH.[UpdatedBy],JBD.[JournalBatchDetailId],JBH.[Module],JBD.[DebitAmount],JBD.[CreditAmount],  
  -- JBD.[JournalTypeNumber],JBD.[EntryDate],JBD.[JournalTypeName],JT.[JournalTypeCode],JBD.[CreatedDate],  
  -- JBD.[UpdatedDate],JBD.[CreatedBy],JBD.[UpdatedBy], CD.CreditAmount,CD.DebitAmount,CD.GlAccountName,CD.GlAccountNumber,CD.TransactionDate,BS.[Name],DM.DistributionCode
     ORDER BY JBH.[EntryDate],JBD.[JournalBatchDetailId] DESC;  
    END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetMultipleJournalBatchHeaderById'     
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