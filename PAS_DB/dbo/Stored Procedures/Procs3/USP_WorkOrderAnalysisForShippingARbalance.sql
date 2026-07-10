
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_WorkOrderAnalysisForShippingARbalance   (source: PAS_DB/dbo/Stored Procedures/Procs3/USP_WorkOrderAnalysisForShippingARbalance.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_WorkOrderAnalysisForShippingARbalance]           
 ** Author: [Ayushi Patel]  
 ** Description: This stored procedure is used to analyze Work Order for Shipping AR balance.  
 ** Date:   [17/03/2025]  
 ** PARAMETERS:  
 **   @WorkOrderId BIGINT,  
 **   @WorkOrderPartNoId BIGINT  
 ** RETURN VALUE: Result set with work order analysis details  
 **************************************************************  
 ** Change History  
 **************************************************************  
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    17/03/2025   Ayushi Patel     Created
	2    03/07/2025   Moin Bloch       Changed Old To New Billing Table
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

    USP_WorkOrderAnalysisForShippingARbalance 8473 , 8128
**************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_WorkOrderAnalysisForShippingARbalance]  
@WorkOrderId BIGINT,  
@WorkOrderPartNoId BIGINT  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    BEGIN TRY  
        BEGIN TRANSACTION  

		DECLARE @WOModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';

        -- Create a temporary table for Quote List  
        CREATE TABLE #QuoteTable  
        (  
            WorkOrderId BIGINT,  
            WOPartNoId BIGINT,  
            Revenue DECIMAL(18, 2)  
        );  

        INSERT INTO #QuoteTable  
        SELECT DISTINCT  
            wo.WorkOrderId,  
            wqd.WOPartNoId,  
            CASE  
                WHEN wqd.QuoteMethod = 1 THEN ISNULL(wqd.CommonFlatRate, 0)  
                ELSE  
                    ISNULL(wqd.MaterialFlatBillingAmount, 0) +  
                    ISNULL(wqd.LaborFlatBillingAmount, 0) +  
                    ISNULL(wqd.ChargesFlatBillingAmount, 0)  
            END AS Revenue  
        FROM dbo.WorkOrder wo WITH (NOLOCK)  
        INNER JOIN dbo.WorkOrderQuote woq WITH (NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId  
        INNER JOIN dbo.WorkOrderQuoteDetails wqd WITH (NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId  
        WHERE wo.WorkOrderId = @WorkOrderId AND wqd.WOPartNoId = @WorkOrderPartNoId;  

        -- Fetching Work Order Analysis  
        SELECT DISTINCT  
            wop.ID,  
            im.PartNumber,  
            im.PartDescription,  
            im.RevisedPart AS RevisedPartNo,  
            CASE  
                WHEN EXISTS (SELECT 1 FROM #QuoteTable q WHERE q.WorkOrderId = woc.WorkOrderId AND q.WOPartNoId = woc.WOPartNoId)  
                THEN (SELECT TOP 1 ISNULL(q.Revenue, 0) FROM #QuoteTable q WHERE q.WorkOrderId = woc.WorkOrderId AND q.WOPartNoId = woc.WOPartNoId)  
                ELSE ISNULL(woc.Revenue, 0)  
            END AS Revenue  
        FROM dbo.WorkOrderMPNCostDetails woc WITH (NOLOCK)  
        INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON woc.WorkOrderId = wo.WorkOrderId  
        INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON woc.WOPartNoId = wop.ID  
        --LEFT JOIN dbo.WorkOrderBillingInvoicingItem wbi WITH (NOLOCK)  
        --    ON wop.ID = wbi.WorkOrderPartId  
        --    AND ISNULL(wbi.IsVersionIncrease, 0) = 0  
        --    AND ISNULL(wbi.IsPerformaInvoice, 0) = 0  
        --LEFT JOIN dbo.WorkOrderBillingInvoicing wb WITH (NOLOCK)  
        --    ON wbi.BillingInvoicingId = wb.BillingInvoicingId  
        --    AND ISNULL(wb.IsVersionIncrease, 0) = 0  
        --    AND ISNULL(wb.IsPerformaInvoice, 0) = 0  
		LEFT JOIN dbo.BillingInvoicingItems wbi WITH (NOLOCK)  
            ON wop.ID = wbi.SubReferenceId  
            AND ISNULL(wbi.IsVersionIncrease, 0) = 0  
            AND ISNULL(wbi.IsPerformaInvoice, 0) = 0  
			AND wbi.[ModuleId] =@WOModuleId
        LEFT JOIN dbo.BillingInvoicing wb WITH (NOLOCK)  
            ON wbi.BillingInvoicingId = wb.BillingInvoicingId  
            AND ISNULL(wb.IsVersionIncrease, 0) = 0  
            AND ISNULL(wb.IsPerformaInvoice, 0) = 0  
			AND wb.[ModuleId] =@WOModuleId
        INNER JOIN dbo.Customer c WITH (NOLOCK) ON wo.CustomerId = c.CustomerId  
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
        INNER JOIN dbo.WorkOrderStage s WITH (NOLOCK) ON wop.WorkOrderStageId = s.WorkOrderStageId  
        INNER JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON wop.WorkOrderStatusId = st.Id  
        WHERE wo.WorkOrderId = @WorkOrderId  
          AND woc.WOPartNoId = @WorkOrderPartNoId  
         AND ISNULL(im.IsNonStock,0) = 0
           ORDER BY wop.ID;  

        -- Drop the temporary table after usage
        DROP TABLE #QuoteTable;

        COMMIT TRANSACTION  
    END TRY  
    BEGIN CATCH  
        IF @@TRANCOUNT > 0  
        BEGIN  
            PRINT 'ROLLBACK';  
            ROLLBACK TRANSACTION;  
        END  

        DECLARE @ErrorLogID INT,  
                @DatabaseName VARCHAR(100) = DB_NAME(),  
                @AdhocComments VARCHAR(150) = '[USP_WorkOrderAnalysisForShippingARbalance]',  
                @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) +  
                                                      ''', @WorkOrderPartNoId = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS VARCHAR(100)),  
                @ApplicationName VARCHAR(100) = 'PAS';  

        EXEC spLogException  
            @DatabaseName = @DatabaseName,  
            @AdhocComments = @AdhocComments,  
            @ProcedureParameters = @ProcedureParameters,  
            @ApplicationName = @ApplicationName,  
            @ErrorLogID = @ErrorLogID OUTPUT;  

        RAISERROR ('Unexpected error occurred. Please note error number: %d', 16, 1, @ErrorLogID);  
        RETURN (1);  
    END CATCH  
END