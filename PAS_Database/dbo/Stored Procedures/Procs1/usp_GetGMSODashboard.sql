/*************************************************************           
 ** File:   [usp_GetGMSODashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for GMSODashboard 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha		Created
	2	        	  Swetha		Added Transaction & NO LOCK
	3	 01/02/2024	  AMIT GHEDIYA	added isperforma Flage for SO
	4    11/05/2024	  Vishal Suthar	Modified to make use of new SO Part tables
	3    07-07-2025   Moin Bloch    Changed Old To New Billing Table
     
EXECUTE   [dbo].[usp_GetGMSODashboard] 
**************************************************************/
CREATE      PROCEDURE [dbo].[usp_GetGMSODashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
	
	DECLARE @SOModuleId INT
    SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

      SELECT
        SOBI.SubTotal + SOBII.MiscChargesCostPlus + SOBII.FreightCostPlus AS PartsSaleBilling,
        SOPC.marginamount AS PartsSaleGM,
        SOBI.invoicedate 'SALE DATE'
      FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
	  INNER JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBI.BillingInvoicingId = SOBII.BillingInvoicingId
      INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
      INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
      INNER JOIN dbo.SalesOrderPartCost SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
	  WHERE ISNULL(SOBI.IsPerformaInvoice,0) = 0  AND SOBI.[ModuleId] = @SOModuleId
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[usp_GetGMSODashboard]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
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