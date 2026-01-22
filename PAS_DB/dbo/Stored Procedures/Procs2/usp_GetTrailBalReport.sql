/*************************************************************           
 ** File:   [usp_GetTrailBalReport]           
 ** Author:   Swetha  
 ** Description: Get Data for TrailBal Report   
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
     
EXECUTE   [dbo].[usp_GetTrailBalReport]-Need to add parameters here
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetTrailBalReport] @fiscalyear int,
@fiscalname varchar(3000),
@mastercompanyid int
--@Level1 varchar(max) = null,
--@Level2 varchar(max) = null,
--@Level3 varchar(max) = null,
--@Level4 varchar(max) = null
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
        GLAC.glaccountclassname 'Acct Type',
        '?' 'Debit',
        '?' 'Credit',
        '?' 'Bal'

      FROM DBO.GLAccount GLA WITH (NOLOCK)
      LEFT OUTER JOIN DBO.GLAccountClass GLAC WITH (NOLOCK)
        ON GLA.GLAccountTypeId = GLAC.GLAccountClassId
        LEFT OUTER JOIN DBO.Ledger LDGR WITH (NOLOCK)
          ON GLA.LedgerId = LDGR.LedgerId
        LEFT OUTER JOIN DBO.LegalEntity LE WITH (NOLOCK)
          ON LDGR.LegalEntityId = LE.LegalEntityId
        LEFT OUTER JOIN DBO.AccountingCalendar AC WITH (NOLOCK)
          ON LE.LegalEntityId = AC.LegalEntityId

      WHERE AC.FiscalYear IN (@fiscalyear)
      AND AC.FiscalName IN (@fiscalname) and GLA.MasterCompanyId=@mastercompanyid
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetToolsReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1= ''' + CAST(ISNULL(@fiscalyear, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@fiscalname, '') AS varchar(100)),
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