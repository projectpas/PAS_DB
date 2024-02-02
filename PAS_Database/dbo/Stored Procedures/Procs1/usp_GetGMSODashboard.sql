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
     
EXECUTE   [dbo].[usp_GetGMSODashboard] 
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetGMSODashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT
        SOBI.SubTotal + SOBI.MiscCharges + SOBI.Freight AS PartsSaleBilling,
        SOP.marginamount AS PartsSaleGM,
        SOBI.invoicedate 'SALE DATE'
      FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
      INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
      INNER JOIN dbo.SalesOrderPart SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
	  WHERE ISNULL(SOBI.IsProforma,0) = 0
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