/*************************************************************               
 ** File:   [GetCreditMemoById]               
 ** Author:  Amit Ghediya    
 ** Description: This stored procedure is used to Get Credit Memo Calculation Details    
 ** Purpose:             
 ** Date:   17/04/2023          
              
 ** PARAMETERS:     
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author  Change Description                
 ** --   --------     -------  --------------------------------              
    1    17/04/2023  Amit Ghediya    Created    
    2    01/08/2023  Satish Gohil    Modify(Remove Other tax calculation )   
	3	 01/02/2024	 AMIT GHEDIYA	 added isperforma Flage for SO

-- EXEC RPT_PrintCreditMemoCalculationData 34,11,1,394,1969    
    
************************************************************************/    
CREATE   PROCEDURE [dbo].[RPT_PrintCreditMemoCalculationData]    
 @CreditMemoHeaderId bigint,    
 @MasterCompanyId BIGINT,    
 @IsWorkOrder bit,    
 @InvoicingId BIGINT,    
 @CustomerId BIGINT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY    
    
  DECLARE @tmpAwb VARCHAR(200),@ModuleID int = 61,@tmpNotes VARCHAR(MAX),     
  @EmailTemplateTypeId BIGINT, @tmpdescription VARCHAR(MAX),@tmpTotal DECIMAL(18,2),@tmpTotalFreight DECIMAL(18,2),    
  @tmpTotalCharges DECIMAL(18,2),@tmpSubTotals DECIMAL(18,2),@tmpCustomerId BIGINT,@tmpSiteId BIGINT,@tmpSiteTax DECIMAL(18,2),    
  @tmpOtherSiteTax DECIMAL(18,2);    
    
  --SEELCT AWB & NOTES    
  SELECT     
   @tmpAwb = (CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.WayBillRef,NULL) FROM [dbo].[WorkOrderBillingInvoicing] WB WITH (NOLOCK)     
               WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])    
          ELSE     
           (SELECT TOP 1 ISNULL(SAOS.AirwayBill,NULL) FROM [dbo].[SalesOrderBillingInvoicing] SB WITH (NOLOCK)     
            LEFT JOIN SalesOrderBillingInvoicingItem SABI ON SB.SOBillingInvoicingId = SABI.SOBillingInvoicingId AND ISNULL(SABI.IsProforma,0) = 0   
            LEFT JOIN SalesOrderShipping SAOS ON SABI.SalesOrderShippingId = SAOS.SalesOrderShippingId  --and  SAOS.SalesOrderId = 192    
               WHERE SB.[SOBillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsProforma],0) = 0 )    
          END) ,    
   @tmpNotes = ISNULL(CM.[Notes], ''),    
   @tmpTotalFreight = CM.[TotalFreight],    
   @tmpTotalCharges = CM.[TotalCharges]    
   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)     
       INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID    
       LEFT JOIN [dbo].[CustomerRMAHeader] CRMA ON CRMA.RMAHeaderId = CM.RMAHeaderId    
       OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR     
  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;    
    
  --SELECT DESCRIPTION    
  SELECT @EmailTemplateTypeId = EmailTemplateTypeId from EmailTemplateType WHERE EmailTemplateType='CreditMemoPrintPDF';    
    
  IF EXISTS (SELECT TOP 1 TermsConditionId FROM TermsCondition WHERE EmailTemplateTypeId = @EmailTemplateTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0)    
  BEGIN    
  SELECT @tmpdescription = description     
   FROM TermsCondition WITH(NOLOCK)    
   WHERE EmailTemplateTypeId = @EmailTemplateTypeId     
   AND MasterCompanyId = @MasterCompanyId;    
  END    
  ELSE    
  BEGIN    
   SET @tmpdescription = '';    
  END    
  --SET @CreditMemoHeaderId = 15;    
  --SELECT TOTAL    
  IF(@IsWorkOrder = 0)    
  BEGIN    
    SELECT @tmpTotal = SUM(CM.Amount)         
    FROM dbo.CreditMemoDetails CM WITH (NOLOCK)          
     LEFT JOIN dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.SOBillingInvoicingId AND ISNULL(SOBI.IsProforma,0) = 0   
     LEFT JOIN  dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId  AND ISNULL(SOBII.IsProforma,0) = 0  
     LEFT JOIN  dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId AND CM.StocklineId = SOPN.StockLineId    
     LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SOPN.ConditionId    
     LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId=IM.ItemMasterId    
    WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;    
  END    
  ELSE     
  BEGIN    
    SELECT @tmpTotal = SUM(CM.Amount)    
     FROM dbo.CreditMemoDetails CM WITH (NOLOCK)      
     LEFT JOIN dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId    
     LEFT JOIN  dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId    
     LEFT JOIN  dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId AND CM.StocklineId = WOPN.StockLineId        
     LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = WOPN.ConditionId    
     LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId        
    WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;    
  END    
    
  --GET Customer Site    
  SELECT @tmpSiteId = bi.ShipToSiteId    
   FROM SalesOrderBillingInvoicing bi WITH(NOLOCK)    
     INNER JOIN Customer billToCustomer WITH(NOLOCK) ON bi.BillToCustomerId=billToCustomer.CustomerId    
     INNER JOIN [CustomerBillingAddress] billToSite WITH(NOLOCK) ON billToSite.CustomerBillingAddressId=bi.BillToSiteId    
     INNER JOIN [Address] billToAddress WITH(NOLOCK) ON billToAddress.AddressId=billToSite.AddressId    
     INNER JOIN [Countries] ca WITH(NOLOCK) ON ca.countries_id=billToAddress.CountryId    
   WHERE bi.SOBillingInvoicingId = @CustomerId AND ISNULL(bi.IsProforma,0) = 0;    
    
  --Tax Cal Only match site    
  --IF(@tmpSiteId > 0)    
  --BEGIN    
  -- SELECT @tmpSiteTax = SUM(TR.TaxRate)     
  --  FROM CustomerTaxTypeRateMapping  CTR WITH(NOLOCK)    
  --  JOIN TaxRate TR WITH(NOLOCK) ON CTR.TaxRateId = TR.TaxRateId    
  -- WHERE SiteId = @tmpSiteId;    
    
  -- SELECT @tmpOtherSiteTax = SUM(TR.TaxRate)     
  --  FROM CustomerTaxTypeRateMapping  CTR WITH(NOLOCK)    
  --  JOIN TaxRate TR WITH(NOLOCK) ON CTR.TaxRateId = TR.TaxRateId    
  -- WHERE SiteId != @tmpSiteId;    
  --END    
  --ELSE    
  --BEGIN    
  -- SET @tmpSiteTax = 0.00;    
    
  -- SELECT @tmpOtherSiteTax = SUM(TR.TaxRate)     
  --  FROM CustomerTaxTypeRateMapping CTR WITH(NOLOCK)    
  --  JOIN TaxRate TR ON CTR.TaxRateId = TR.TaxRateId    
  -- WHERE CustomerId = @CustomerId;    
  --END     
    
  SET @tmpSubTotals = (ISNULL(@tmpTotalFreight,0.00) + ISNULL(@tmpTotalCharges,0.00) + @tmpTotal);    
    
  SET @tmpTotal = (ISNULL(@tmpSubTotals,0.00) + ISNULL(@tmpSiteTax,0.00) + ISNULL(@tmpOtherSiteTax,0.00));     
    
    
  SELECT ISNULL(@tmpAwb,'') AS Awb, ISNULL(@tmpNotes,'') AS Notes, ISNULL(@tmpdescription,'') AS description, ISNULL(@tmpTotal,0.00) AS Total, ISNULL(@tmpSubTotals,0.00) AS SubTotal, ISNULL(@tmpSiteTax,0.00) AS SalesTax, ISNULL(@tmpOtherSiteTax,0.00) AS OtherTax,    
  ISNULL(@tmpTotalFreight,0.00) AS Freight, ISNULL(@tmpTotalCharges,0.00) AS Charges, @tmpTotal +(CASE WHEN @tmpTotalFreight > 0 THEN @tmpTotalFreight ELSE 0 END) + (CASE WHEN @tmpTotalCharges > 0 THEN @tmpTotalCharges ELSE 0 END) AS FinalTotal;    
    
END TRY        
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'RPT_PrintCreditMemoCalculationData'     
            , @ProcedureParameters VARCHAR(3000)  = '@CreditMemoHeaderId = '''+ ISNULL(@CreditMemoHeaderId, '') + ''    
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