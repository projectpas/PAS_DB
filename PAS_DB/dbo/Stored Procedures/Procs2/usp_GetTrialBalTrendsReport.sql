/*************************************************************           
 ** File:   [usp_GetTrialBalTrendsReport]           
 ** Author:   Swetha  
 ** Description: Get Data for TrialBalTrends Report  
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha Created
	2	        	  Swetha Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetTrialBalTrendsReport] --Need to add parameters here
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetTrialBalTrendsReport] @fromfiscalyear int,
@fromfiscalname varchar(3000),
@tofiscalyear int,
@tofiscalname varchar(3000),
@mastercompanyid int
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      SELECT DISTINCT
        LE.companycode 'CO Code',
        '?' 'BU Code',
        '?' 'Div Code',
        '?' 'Dept Code',
        GLA.accountcode 'GL Acct Code',
        GLA.accountname 'GL Name',
        GLAC.glaccountclassname 'Acct Type'
      FROM DBO.GLAccount GLA WITH (NOLOCK)
      LEFT OUTER JOIN DBO.GLAccountClass GLAC WITH (NOLOCK)
        ON GLA.GLAccountTypeId = GLAC.GLAccountClassId
        LEFT OUTER JOIN DBO.Ledger LDGR WITH (NOLOCK)
          ON GLA.LedgerId = LDGR.LedgerId
        LEFT OUTER JOIN DBO.LegalEntity LE WITH (NOLOCK)
          ON LDGR.LegalEntityId = LE.LegalEntityId
        LEFT OUTER JOIN DBO.AccountingCalendar AC WITH (NOLOCK)
          ON LE.LegalEntityId = AC.LegalEntityId
      WHERE AC.FiscalYear IN (@fromfiscalyear)
      AND AC.FiscalName IN (@fromfiscalname)
      AND AC.FiscalYear IN (@tofiscalyear)
      AND AC.FiscalName IN (@tofiscalname) and GLA.MasterCompanyId=@mastercompanyid
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetTrialBalTrendsReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1= ''' + CAST(ISNULL(@fromfiscalyear, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@fromfiscalname, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END