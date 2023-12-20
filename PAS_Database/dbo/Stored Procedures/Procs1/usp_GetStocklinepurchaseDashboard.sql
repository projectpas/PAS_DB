
------------------------------------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [usp_GetStocklinepurchaseDashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for StocklinepurchaseDashboard 
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
     
EXECUTE   [dbo].[usp_GetStocklinepurchaseDashboard] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetStocklinepurchaseDashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
	  DECLARE @StockType int = 1;
      SELECT DISTINCT
        POP.ItemType AS ItemType,
        PO.purchaseordernumber AS #ofPO,
        SUM(pop.ExtendedCost) AS Amount,
        CNDN.description AS Cond,
        PO.vendorname AS Vendor,
        V.createdby AS CreatedBy,
        --VNDR.createddate as DateCreated,
        PO.CreatedDate AS POCreateDate,
        ISNULL(A.ClassificationName, '') 'ClassificationName'
      FROM PurchaseOrder PO WITH (NOLOCK)
      LEFT JOIN Stockline STL WITH (NOLOCK)
        ON PO.PurchaseOrderId = STL.purchaseorderid
        LEFT JOIN PurchaseOrderPart POP WITH (NOLOCK)
          ON PO.PurchaseOrderId = POP.PurchaseOrderId AND POP.ItemTypeId = @StockType
        LEFT JOIN Vendor V WITH (NOLOCK)
          ON PO.VendorId = V.VendorId
        LEFT JOIN Condition CNDN WITH (NOLOCK)
          ON POP.ConditionId = CNDN.ConditionId
        OUTER APPLY (SELECT
          STUFF((SELECT
            ', ' + VC.ClassificationName
          FROM ClassificationMapping CM
          INNER JOIN VendorClassification VC WITH (NOLOCK)
            ON VC.VendorClassificationId = CM.ClasificationId
          WHERE CM.ReferenceId = V.VendorId
          AND CM.ModuleId = 3
          FOR xml PATH (''))
          , 1, 1, '') ClassificationName) A

      GROUP BY POP.ItemType,
               PO.purchaseordernumber,
               CNDN.description,
               PO.vendorname,
               V.createdby,
               PO.CreatedDate,
               ISNULL(A.ClassificationName, '')

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetStocklinepurchaseDashboard]',
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