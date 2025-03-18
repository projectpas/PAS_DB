
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

    USP_WorkOrderAnalysisForShippingARbalance 8473 , 8128
**************************************************************/  

CREATE   PROCEDURE [dbo].[USP_WorkOrderAnalysisForShippingARbalance]  
    @WorkOrderId BIGINT,  
    @WorkOrderPartNoId BIGINT  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    BEGIN TRY  
        BEGIN TRANSACTION  

        -- Fetching Quote List  
        DECLARE @QuoteTable TABLE  
        (  
            WorkOrderId BIGINT,  
            WOPartNoId BIGINT,  
            Revenue DECIMAL(18, 2)  
        );  

        INSERT INTO @QuoteTable  
        SELECT DISTINCT  
            wo.WorkOrderId,  
            wqd.WOPartNoId,  
            ISNULL(  
                CASE WHEN wqd.QuoteMethod = 1 THEN wqd.CommonFlatRate  
                     ELSE wqd.MaterialFlatBillingAmount + wqd.LaborFlatBillingAmount + wqd.ChargesFlatBillingAmount  
                END,  
            0) AS Revenue  
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
            ISNULL(  
                (SELECT TOP 1 q.Revenue FROM @QuoteTable q  
                 WHERE q.WorkOrderId = woc.WorkOrderId AND q.WOPartNoId = woc.WOPartNoId),  
                ISNULL(woc.Revenue, 0)  
            ) AS Revenue  
        FROM dbo.WorkOrderMPNCostDetails woc WITH (NOLOCK)  
        INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON woc.WorkOrderId = wo.WorkOrderId  
        INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON woc.WOPartNoId = wop.ID  
        LEFT JOIN dbo.WorkOrderBillingInvoicingItem wbi WITH (NOLOCK)  
            ON wop.ID = wbi.WorkOrderPartId  
            AND wbi.IsVersionIncrease = 0  
            AND wbi.IsPerformaInvoice = 0  
        LEFT JOIN dbo.WorkOrderBillingInvoicing wb WITH (NOLOCK)  
            ON wbi.BillingInvoicingId = wb.BillingInvoicingId  
            AND wb.IsVersionIncrease = 0  
            AND wb.IsPerformaInvoice = 0  
        INNER JOIN dbo.Customer c WITH (NOLOCK) ON wo.CustomerId = c.CustomerId  
        INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON wop.ItemMasterId = im.ItemMasterId  
        INNER JOIN dbo.WorkOrderStage s WITH (NOLOCK) ON wop.WorkOrderStageId = s.WorkOrderStageId  
        INNER JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON wop.WorkOrderStatusId = st.Id  
        WHERE wo.WorkOrderId = @WorkOrderId  
          AND woc.WOPartNoId = @WorkOrderPartNoId  
        ORDER BY wop.ID;  

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