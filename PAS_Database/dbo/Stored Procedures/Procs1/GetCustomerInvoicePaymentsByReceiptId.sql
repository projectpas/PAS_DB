/*************************************************************                 
 ** File:   [GetCustomerInvoicePaymentsByReceiptId]      
 ** Author:       
 ** Description: This stored procedure is used to populate Invoice Payment by Id.          
 ** Purpose:               
 ** Date:         
                
 ** PARAMETERS:      
               
 ** RETURN VALUE:                 
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author			Change Description                  
 ** --   --------     -------		  --------------------------------                
    1    05/03/2022   Vishal Suthar		Fixed Management Structure binding      
	2    19/05/2023   Satish Gohil		Show only legal entity releted invoice 
	3    22/11/2023   AMIT GHEDIYA		Modify(FOR Exchange Invoice)
	4    05/01/2024   Moin Bloch		Replaced PercentId at CreditTermsId
	5    08/01/2024   Moin Bloch		Replaced Days insted of NetDays
	6	 01/31/2024	  Devendra Shekh	added isperforma Flage for WO

      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 90,0,2      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 10135,0,2,11      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 153,0,2,24      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 10153,0,2,68      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 154,0,2,34      
-- EXEC GetCustomerInvoicePaymentsByReceiptId 61,0,2,14      
    
EXEC GetCustomerInvoicePaymentsByReceiptId 71,0,2,135      
      
**************************************************************/      
CREATE     PROCEDURE [dbo].[GetCustomerInvoicePaymentsByReceiptId]      
@ReceiptId BIGINT = NULL,      
@PageIndex int = NULL,      
@Opr int = NULL,      
@CustomerId BIGINT=NULL,
@legalEntityId BIGINT
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON      
 BEGIN TRY      
  DECLARE @SOMSModuleID INT = 17, @WOMSModuleID INT = 12;    
  DECLARE @CMSModuleID INT = 61, @ESOMSModuleID INT = 68;    
  IF(@Opr=1)      
  BEGIN      
   SELECT [PaymentId]      
         ,[CustomerId]      
         ,[SOBillingInvoicingId]      
         ,[ReceiptId]      
         ,[IsMultiplePaymentMethod]      
         ,[IsCheckPayment]      
         ,[IsWireTransfer]      
         ,[IsEFT]      
         ,[IsCCDCPayment]      
         ,[MasterCompanyId]      
         ,[PaymentAmount]      
         ,[DiscAmount]      
         ,[DiscType]      
         ,[BankFeeAmount]      
         ,[BankFeeType]      
         ,[OtherAdjustAmt]      
         ,[Reason]      
         ,[RemainingBalance]      
         ,[Status]      
         ,[CreatedBy]      
         ,[UpdatedBy]      
         ,[CreatedDate]      
         ,[UpdatedDate]      
         ,[IsActive]      
         ,[IsDeleted]      
         ,[IsDeposite]      
         ,[IsTradeReceivable]      
         ,[TradeReceivableORMiscReceiptGLAccnt]      
         ,[CtrlNum]      
         ,[InvoiceType]      
         ,[OriginalAmount]      
         ,[NewRemainingBal]      
         ,[DocNum]      
         ,[CurrencyCode]      
         ,[FxRate]      
         ,[WOSONum]      
         ,[DSI]      
         ,[DSO]      
         ,[AmountPastDue]      
         ,[ARBalance]      
         ,[InvDueDate]      
         ,[CreditLimit]      
         ,[CreditTermName]      
         ,[LastMSLevel]      
         ,[AllMSlevels]      
         ,[PageIndex]      
         ,[RemainingAmount]      
         ,[InvoiceDate]      
         ,[Id]      
         ,[GLARAccount]      
     FROM [dbo].[InvoicePayments] WITH (NOLOCK) WHERE ReceiptId = @ReceiptId ORDER BY PageIndex      
  END      
  IF(@Opr=2)      
  BEGIN      
   ;WITH CTE AS(      
		SELECT [PaymentId],INV.[CustomerId],INV.[SOBillingInvoicingId],[ReceiptId],INV.[MasterCompanyId],0 AS [IsMultiplePaymentMethod],0 AS [IsCheckPayment],0 AS [IsWireTransfer],0 AS [IsEFT],0 AS [IsCCDCPayment]      
              ,[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],INV.[Reason],[RemainingBalance],INV.[Status]      
              ,INV.[CreatedBy],INV.[UpdatedBy],INV.[CreatedDate],INV.[UpdatedDate],INV.[IsActive],INV.[IsDeleted],0 AS [IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
              ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]      
              ,INV.[CreditLimit],INV.[CreditTermName], CASE WHEN INV.[LastMSLevel] IS NOT NULL THEN INV.[LastMSLevel] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[LastMSLevel] WHEN InvoiceType = 2 THEN MSD_WO.[LastMSLevel] WHEN InvoiceType = 6 THEN EMSD.[LastMSLevel] ELSE MSD_CM.[LastMSLevel] END END LastMSLevel,      
               CASE WHEN INV.[AllMSlevels] IS NOT NULL THEN INV.[AllMSlevels] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[AllMSlevels] WHEN InvoiceType = 2 THEN MSD_WO.[AllMSlevels] WHEN InvoiceType = 6 THEN EMSD.[AllMSlevels] ELSE MSD_CM.[AllMSlevels] END  END AllMSlevels,      
               [PageIndex],   
               CASE WHEN InvoiceType = 1 THEN SOBI.RemainingAmount     
               WHEN InvoiceType = 2 THEN WOBI.RemainingAmount  WHEN InvoiceType = 6 THEN ESOBI.RemainingAmount ELSE 0 END AS 'RemainingAmount',      
               INV.[InvoiceDate],[Id],[GLARAccount]      
               ,CASE WHEN INV.IsDeleted = 1 THEN 0 ELSE 1 END AS 'Selected',  
     
			   CASE WHEN InvoiceType = 1 THEN CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.InvoiceDate AS DATETIME))) END  
			   WHEN InvoiceType = 2 THEN CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CTW.[Days],0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CTW.[Days],0), (CAST(WOBI.InvoiceDate AS DATETIME))) END  
			   WHEN InvoiceType = 6 THEN CASE WHEN ISNULL(ESOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.InvoiceDate AS DATETIME))) END  
			   ELSE NULL END AS 'DiscountDate',    
  
			   CASE WHEN InvoiceType = 1 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(ps.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
			   WHEN InvoiceType = 2 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate as DATETIME) + ISNULL(CTW.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(pw.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
			   WHEN InvoiceType = 6 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(ESOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((ESOBI.GrandTotal * ISNULL(ps.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
			   ELSE 0 END AS 'DiscountAvailable'    
  
     FROM [dbo].[InvoicePayments] INV WITH (NOLOCK)      
      LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId     
      LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = INV.SOBillingInvoicingId    
	  LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK) ON ESOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId
      LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) ON WOBI.BillingInvoicingId = wobii.BillingInvoicingId      
      LEFT JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON INV.SOBillingInvoicingId = CM.CreditMemoHeaderId    
      LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD_WO WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId   
	  LEFT JOIN [dbo].[ExchangeManagementStructureDetails] EMSD WITH (NOLOCK) ON EMSD.ModuleID = @ESOMSModuleID AND EMSD.ReferenceID = ESOBI.ExchangeSalesOrderId 
      LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD_CM WITH (NOLOCK) ON MSD.ModuleID = @CMSModuleID AND MSD.ReferenceID =  CM.CreditMemoHeaderId     
      LEFT JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId        
      LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId        
      LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON S.CreditTermId = CT.CreditTermsId    
      LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.WorkOrderId  and WOBI.IsVersionIncrease = 0        
      LEFT JOIN [dbo].[CustomerFinancial] CFW WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId        
      LEFT JOIN [dbo].[CreditTerms] CTW WITH (NOLOCK) ON WO.CreditTermId = CTW.CreditTermsId        
      LEFT JOIN [dbo].[Percent] ps WITH(NOLOCK) ON CAST(CT.PercentId AS INT) = ps.PercentId        
      LEFT JOIN [dbo].[Percent] pw WITH(NOLOCK) ON CAST(CTW.PercentId AS INT) = pw.PercentId        
      
	  WHERE [ReceiptId] = @ReceiptId AND PageIndex=@PageIndex AND INV.CustomerId=@CustomerId      
      
     UNION      
      
     SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId    ELSE 0 END AS 'PaymentId',      
		  SOBI.CustomerId,SOBI.SOBillingInvoicingId,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId    ELSE 0 END AS 'ReceiptId'      
		  ,SOBI.MasterCompanyId,      
		  0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount    ELSE 0 END AS PaymentAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount    ELSE 0 END AS DiscAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType    ELSE 0 END AS DiscType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount    ELSE 0 END AS BankFeeAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType    ELSE 0 END AS BankFeeType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt    ELSE 0 END AS OtherAdjustAmt,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason    ELSE 0 END AS Reason,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE SOBI.RemainingAmount END AS RemainingBalance,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE '' END AS [Status],      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE SOBI.CreatedBy END AS 'CreatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE SOBI.UpdatedBy END AS 'UpdatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE SOBI.CreatedDate END AS 'CreatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE SOBI.UpdatedDate END AS 'UpdatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE SOBI.IsActive END AS 'IsActive',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE SOBI.IsDeleted END AS 'IsDeleted',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',1 AS 'InvoiceType',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount    ELSE SOBI.GrandTotal END AS 'OriginalAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE SOBI.InvoiceNo END AS DocNum,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CR.Code END AS 'CurrencyCode',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE SO.SalesOrderNumber END AS 'WOSONum',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
		  NULL AS 'InvDueDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE CF.CreditLimit END AS 'CreditLimit',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE CT.[Name] END AS 'CreditTermName',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(SOBI.RemainingAmount,0)    ELSE SOBI.RemainingAmount END AS 'RemainingAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE SOBI.InvoiceDate END AS 'InvoiceDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE SO.SalesOrderId END AS 'Id',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
		  CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,  
		  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END AS DiscountAvailable        
     
	FROM [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK)      
      INNER JOIN [dbo].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId      
      INNER JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CF.CustomerId=SO.CustomerId      
      INNER JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId=SO.CreditTermId      
      INNER JOIN [dbo].[Currency] CR WITH (NOLOCK) ON CR.CurrencyId=SOBI.CurrencyId      
       LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(CT.PercentId as INT) = p.PercentId        
       LEFT JOIN [dbo].[InvoicePayments] IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND IPT.InvoiceType=1 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
      INNER JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId AND MSD.Level1Id = @legalEntityId      
      
	  WHERE SOBI.CustomerId=@CustomerId AND SOBI.InvoiceStatus = 'Invoiced' AND SOBI.RemainingAmount > 0      
      
      UNION      
      
      SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId    ELSE 0 END AS 'PaymentId',      
		  WOBI.CustomerId,WOBI.BillingInvoicingId AS SOBillingInvoicingId,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId    ELSE 0 END AS 'ReceiptId'      
		  ,WOBI.MasterCompanyId,      
		  0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount    ELSE 0 END AS PaymentAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount    ELSE 0 END AS DiscAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType    ELSE 0 END AS DiscType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount    ELSE 0 END AS BankFeeAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType    ELSE 0 END AS BankFeeType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt    ELSE 0 END AS OtherAdjustAmt,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason    ELSE 0 END AS Reason,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE WOBI.RemainingAmount END AS RemainingBalance,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE '' END AS [Status],      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE WOBI.CreatedBy END AS 'CreatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE WOBI.UpdatedBy END AS 'UpdatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE WOBI.CreatedDate END AS 'CreatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE WOBI.UpdatedDate END AS 'UpdatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE WOBI.IsActive END AS 'IsActive',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE WOBI.IsDeleted END AS 'IsDeleted',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt      
		  ,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',2 AS 'InvoiceType',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount    ELSE WOBI.GrandTotal END AS 'OriginalAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE WOBI.InvoiceNo END AS DocNum,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CR.Code END AS 'CurrencyCode',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE WO.WorkOrderNum END AS 'WOSONum',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
		  NULL AS 'InvDueDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE WO.CreditLimit END AS 'CreditLimit',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE WO.CreditTerms END AS 'CreditTermName',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingAmount    ELSE WOBI.RemainingAmount END AS 'RemainingAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE WOBI.InvoiceDate END AS 'InvoiceDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE WO.WorkOrderId END AS 'Id',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
		  CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(WOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,        
		  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END AS DiscountAvailable       
  
     FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK)      
     LEFT JOIN  [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId AND ISNULL(WOBII.IsPerformaInvoice, 0) = 0
     LEFT JOIN  [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId      
     LEFT JOIN  [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId      
     INNER JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CF.CustomerId=WOBI.CustomerId      
     INNER JOIN [dbo].[Currency] CR WITH (NOLOCK) ON CR.CurrencyId=WOBI.CurrencyId      
     LEFT JOIN  [dbo].[CreditTerms] CT WITH (NOLOCK) ON WO.CreditTermId = CT.CreditTermsId        
     LEFT JOIN  [dbo].[Percent] p WITH(NOLOCK) ON CAST(CT.PercentId as INT) = p.PercentId        
     LEFT JOIN  [dbo].[InvoicePayments] IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = WOBI.BillingInvoicingId AND IPT.InvoiceType=2 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
     INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId AND MSD.Level1Id = @legalEntityId      
     WHERE WOBI.CustomerId=@CustomerId AND WOBI.InvoiceStatus = 'Invoiced' AND WOBI.RemainingAmount > 0      
    
  UNION     
    
  SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId ELSE 0 END AS 'PaymentId',      
      CM.CustomerId,CM.CreditMemoHeaderId AS SOBillingInvoicingId,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId ELSE 0 END AS 'ReceiptId'      
      ,CM.MasterCompanyId,      
      0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount  ELSE 0 END AS PaymentAmount,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount ELSE 0 END AS DiscAmount,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType ELSE 0 END AS DiscType,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount  ELSE 0 END AS BankFeeAmount,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType  ELSE 0 END AS BankFeeType,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt  ELSE 0 END AS OtherAdjustAmt,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason ELSE 0 END AS Reason,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE 0 END AS RemainingBalance,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE 'Fulfilling' END AS [Status],      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE CM.CreatedBy END AS 'CreatedBy',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE CM.UpdatedBy END AS 'UpdatedBy',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE CM.CreatedDate END AS 'CreatedDate',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE CM.UpdatedDate END AS 'UpdatedDate',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE CM.IsActive END AS 'IsActive',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE CM.IsDeleted END AS 'IsDeleted',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt      
      ,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',    
      3 AS 'InvoiceType',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount ELSE     
      (SELECT SUM(ISNULL(CMD.AMOUNT,0)) FROM dbo.CreditMemoDetails CMD WHERE CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0) END AS 'OriginalAmount',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE CM.CreditMemoNumber END AS DocNum,      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CASE WHEN CM.IsWorkOrder = 1 THEN WCurr.Code ELSE SCurr.Code END END AS 'CurrencyCode',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE CM.InvoiceNumber END AS 'WOSONum',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
      NULL AS 'InvDueDate',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE 0 END AS 'CreditLimit',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE '' END AS 'CreditTermName',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingAmount    ELSE 0 END AS 'RemainingAmount',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE CM.InvoiceDate END AS 'InvoiceDate',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE CM.CreditMemoHeaderId END AS 'Id',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
      CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected' ,  
      NULL AS DiscountDate,        
      0 AS DiscountAvailable   
     FROM [dbo].[CreditMemo] CM WITH (NOLOCK)      
	  INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
	   LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON CMD.InvoiceId =  SOBI.SOBillingInvoicingId AND CMD.IsWorkOrder = 0   
	   LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON CMD.InvoiceId =  WOBI.BillingInvoicingId AND CMD.IsWorkOrder = 1    
	   LEFT JOIN [dbo].[Currency] WCurr WITH (NOLOCK) ON WOBI.CurrencyId = WCurr.CurrencyId      
	   LEFT JOIN [dbo].[Currency] SCurr WITH (NOLOCK) ON SOBI.CurrencyId = SCurr.CurrencyId      
       LEFT JOIN [dbo].[InvoicePayments] IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = CM.CreditMemoHeaderId AND IPT.InvoiceType=3 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
      INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId AND MSD.Level1Id = @legalEntityId   
     WHERE CM.CustomerId=@CustomerId AND CM.Status = 'Fulfilling'
	 
	  UNION      
      
     SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId    ELSE 0 END AS 'PaymentId',      
		  ESOBI.CustomerId,ESOBI.SOBillingInvoicingId,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId    ELSE 0 END AS 'ReceiptId'      
		  ,ESOBI.MasterCompanyId,      
		  0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount    ELSE 0 END AS PaymentAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount    ELSE 0 END AS DiscAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType    ELSE 0 END AS DiscType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount    ELSE 0 END AS BankFeeAmount,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType    ELSE 0 END AS BankFeeType,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt    ELSE 0 END AS OtherAdjustAmt,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason    ELSE 0 END AS Reason,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE ESOBI.RemainingAmount END AS RemainingBalance,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE '' END AS [Status],      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE ESOBI.CreatedBy END AS 'CreatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE ESOBI.UpdatedBy END AS 'UpdatedBy',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE ESOBI.CreatedDate END AS 'CreatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE ESOBI.UpdatedDate END AS 'UpdatedDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE ESOBI.IsActive END AS 'IsActive',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE ESOBI.IsDeleted END AS 'IsDeleted',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',1 AS 'InvoiceType',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount    ELSE ESOBI.GrandTotal END AS 'OriginalAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE ESOBI.InvoiceNo END AS DocNum,      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CR.Code END AS 'CurrencyCode',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE ESO.ExchangeSalesOrderNumber END AS 'WOSONum',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
		  NULL AS 'InvDueDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE CF.CreditLimit END AS 'CreditLimit',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE CT.[Name] END AS 'CreditTermName',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(ESOBI.RemainingAmount,0)    ELSE ESOBI.RemainingAmount END AS 'RemainingAmount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE ESOBI.InvoiceDate END AS 'InvoiceDate',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE ESO.ExchangeSalesOrderId END AS 'Id',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
		  CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
		  CASE WHEN ISNULL(ESOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,  
		  CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(ESOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((ESOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END AS DiscountAvailable        
     
	FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK)      
      INNER JOIN [dbo].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId=ESOBI.ExchangeSalesOrderId      
      INNER JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CF.CustomerId=ESO.CustomerId      
      INNER JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId=ESO.CreditTermId      
      INNER JOIN [dbo].[Currency] CR WITH (NOLOCK) ON CR.CurrencyId=ESOBI.CurrencyId      
       LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON CAST(CT.PercentId as INT) = p.PercentId        
       LEFT JOIN [dbo].[InvoicePayments] IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = ESOBI.SOBillingInvoicingId AND IPT.InvoiceType=1 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
      INNER JOIN [dbo].[ExchangeManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ESOMSModuleID AND MSD.ReferenceID = ESO.ExchangeSalesOrderId AND MSD.Level1Id = @legalEntityId      
      
	  WHERE ESOBI.CustomerId=@CustomerId AND ESOBI.InvoiceStatus = 'Invoiced' AND ESOBI.RemainingAmount > 0 
	 )
	 

     SELECT [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]      
          ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]      
          ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
          ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]      
          ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected],[DiscountDate],[DiscountAvailable] FROM CTE      
     GROUP BY [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]      
          ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]      
          ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
          ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]      
          ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected],[DiscountDate],[DiscountAvailable]    
     ORDER BY [Selected] DESC,[InvoiceType]    
      
  END      
  IF(@Opr=3)--for view invoice list--      
  BEGIN      
   ;WITH CTE AS(      
     SELECT [PaymentId],INV.[CustomerId],INV.[SOBillingInvoicingId],[ReceiptId],INV.[MasterCompanyId],0 AS [IsMultiplePaymentMethod],0 AS [IsCheckPayment],0 AS [IsWireTransfer],0 AS [IsEFT],0 AS [IsCCDCPayment]      
           ,[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],INV.[Reason],[RemainingBalance],INV.[Status]      
           ,INV.[CreatedBy],INV.[UpdatedBy],INV.[CreatedDate],INV.[UpdatedDate],INV.[IsActive],INV.[IsDeleted],0 AS [IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
           ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate],INV.[CreditLimit],INV.[CreditTermName],     
            CASE WHEN INV.[LastMSLevel] IS NOT NULL THEN INV.[LastMSLevel] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[LastMSLevel] WHEN InvoiceType = 2 THEN MSD_WO.[LastMSLevel]  WHEN InvoiceType = 6 THEN EMSD.[LastMSLevel] ELSE MSD_CM.[LastMSLevel]  END END LastMSLevel,      
            CASE WHEN INV.[AllMSlevels] IS NOT NULL THEN INV.[AllMSlevels] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[AllMSlevels] WHEN InvoiceType = 2 THEN MSD_WO.[AllMSlevels] WHEN InvoiceType = 6 THEN EMSD.[AllMSlevels] ELSE MSD_CM.[AllMSlevels] END  END AllMSlevels,      
            [PageIndex],  CASE WHEN InvoiceType = 1 THEN SOBI.RemainingAmount WHEN InvoiceType = 2 THEN WOBI.RemainingAmount WHEN InvoiceType = 6 THEN ESOBI.RemainingAmount ELSE 0 END AS 'RemainingAmount',      
            INV.[InvoiceDate],[Id],[GLARAccount]      
           ,CASE WHEN INV.IsDeleted = 1 THEN 0 ELSE 1 END AS 'Selected',   
       
		   CASE WHEN InvoiceType = 1 THEN CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(SOBI.InvoiceDate AS DATETIME))) END  
		   WHEN InvoiceType = 2 THEN CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CTW.[Days],0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CTW.[Days],0), (CAST(WOBI.InvoiceDate AS DATETIME))) END  
		   WHEN InvoiceType = 6 THEN CASE WHEN ISNULL(ESOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.[Days],0), (CAST(ESOBI.InvoiceDate AS DATETIME))) END  
		   ELSE NULL END AS 'DiscountDate',    
  
		   CASE WHEN InvoiceType = 1 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(ps.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
		   WHEN InvoiceType = 2 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate as DATETIME) + ISNULL(CTW.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(pw.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
		   WHEN InvoiceType = 6 THEN CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(ESOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((ESOBI.GrandTotal * ISNULL(ps.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END  
		   ELSE 0 END AS 'DiscountAvailable'    
  
      FROM [dbo].[InvoicePayments] INV WITH (NOLOCK)      
      LEFT JOIN [dbo].[SalesOrderBillingInvoicing] SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId      
      LEFT JOIN [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = INV.SOBillingInvoicingId      
	  LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicing] ESOBI WITH (NOLOCK) ON ESOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId  
      LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId      
      LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId      
      LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] MSD_WO WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId    
	  LEFT JOIN [dbo].[ExchangeManagementStructureDetails] EMSD WITH (NOLOCK) ON EMSD.ModuleID = @ESOMSModuleID AND EMSD.ReferenceID = ESOBI.ExchangeSalesOrderId      
      LEFT JOIN [dbo].[CreditMemo] CM WITH(NOLOCK) ON INV.SOBillingInvoicingId = CM.CreditMemoHeaderId    
      LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD_CM WITH (NOLOCK) ON MSD.ModuleID = @CMSModuleID AND MSD.ReferenceID =  CM.CreditMemoHeaderId     
      LEFT JOIN [dbo].[SalesOrder] S WITH (NOLOCK) ON SOBI.SalesOrderId = S.SalesOrderId        
      LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId        
      LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON S.CreditTermId = CT.CreditTermsId    
      LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON  WO.WorkOrderId = WOBI.WorkOrderId  and WOBI.IsVersionIncrease = 0        
      LEFT JOIN [dbo].[CustomerFinancial] CFW WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId        
      LEFT JOIN [dbo].[CreditTerms] CTW WITH (NOLOCK) ON WO.CreditTermId = CTW.CreditTermsId        
      LEFT JOIN [dbo].[Percent] ps WITH(NOLOCK) ON CAST(CT.PercentId as INT) = ps.PercentId        
      LEFT JOIN [dbo].[Percent] pw WITH(NOLOCK) ON CAST(CTW.PercentId as INT) = pw.PercentId        
  
      WHERE ReceiptId = @ReceiptId AND PageIndex=@PageIndex AND INV.CustomerId=@CustomerId      
      
  --   UNION      
      
  --   SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId    ELSE 0 END AS 'PaymentId',      
  --    SOBI.CustomerId,SOBI.SOBillingInvoicingId,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId    ELSE 0 END AS 'ReceiptId'      
  --    ,SOBI.MasterCompanyId,      
  --    0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount    ELSE 0 END AS PaymentAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount    ELSE 0 END AS DiscAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType    ELSE 0 END AS DiscType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount    ELSE 0 END AS BankFeeAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType    ELSE 0 END AS BankFeeType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt    ELSE 0 END AS OtherAdjustAmt,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason    ELSE 0 END AS Reason,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE SOBI.RemainingAmount END AS RemainingBalance,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE '' END AS [Status],      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE SOBI.CreatedBy END AS 'CreatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE SOBI.UpdatedBy END AS 'UpdatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE SOBI.CreatedDate END AS 'CreatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE SOBI.UpdatedDate END AS 'UpdatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE SOBI.IsActive END AS 'IsActive',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE SOBI.IsDeleted END AS 'IsDeleted',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt      
  --    ,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',1 AS 'InvoiceType',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount    ELSE SOBI.GrandTotal END AS 'OriginalAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE SOBI.InvoiceNo END AS DocNum,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CR.Code END AS 'CurrencyCode',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE SO.SalesOrderNumber END AS 'WOSONum',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
  --    NULL AS 'InvDueDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE CF.CreditLimit END AS 'CreditLimit',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE CT.[Name] END AS 'CreditTermName',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(SOBI.RemainingAmount,0)    ELSE SOBI.RemainingAmount END AS 'RemainingAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE SOBI.InvoiceDate END AS 'InvoiceDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE SO.SalesOrderId END AS 'Id',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
  -- CASE WHEN ISNULL(SOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.NetDays,0), (CAST(SOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.NetDays,0), (CAST(SOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,  
  -- CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(SOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((SOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END AS DiscountAvailable        
  --    FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)      
  --    INNER JOIN SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId      
  --    INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=SO.CustomerId      
  --    INNER JOIN CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId=SO.CreditTermId      
  -- LEFT JOIN [Percent] p WITH(NOLOCK) ON CAST(CT.CreditTermsId as INT) = p.PercentId     
  --    INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=SOBI.CurrencyId      
  --    LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND IPT.InvoiceType=1 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
  --    INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId AND MSD.Level1Id = @legalEntityId     
  --    where SOBI.CustomerId=@CustomerId AND SOBI.InvoiceStatus = 'Invoiced'      
      
  --    UNION      
      
  --    SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId    ELSE 0 END AS 'PaymentId',      
  --    WOBI.CustomerId,WOBI.BillingInvoicingId AS SOBillingInvoicingId,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId    ELSE 0 END AS 'ReceiptId'      
  --    ,WOBI.MasterCompanyId,      
  --    0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount    ELSE 0 END AS PaymentAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount    ELSE 0 END AS DiscAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType    ELSE 0 END AS DiscType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount    ELSE 0 END AS BankFeeAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType    ELSE 0 END AS BankFeeType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt    ELSE 0 END AS OtherAdjustAmt,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason    ELSE 0 END AS Reason,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE WOBI.RemainingAmount END AS RemainingBalance,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE '' END AS [Status],      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE WOBI.CreatedBy END AS 'CreatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE WOBI.UpdatedBy END AS 'UpdatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE WOBI.CreatedDate END AS 'CreatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE WOBI.UpdatedDate END AS 'UpdatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE WOBI.IsActive END AS 'IsActive',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE WOBI.IsDeleted END AS 'IsDeleted',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt      
  --    ,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',2 AS 'InvoiceType',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount    ELSE WOBI.GrandTotal END AS 'OriginalAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE WOBI.InvoiceNo END AS DocNum,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CR.Code END AS 'CurrencyCode',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE WO.WorkOrderNum END AS 'WOSONum',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
  --    NULL AS 'InvDueDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE WO.CreditLimit END AS 'CreditLimit',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE WO.CreditTerms END AS 'CreditTermName',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingAmount    ELSE WOBI.RemainingAmount END AS 'RemainingAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE WOBI.InvoiceDate END AS 'InvoiceDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE WO.WorkOrderId END AS 'Id',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
  -- CASE WHEN ISNULL(WOBI.PostedDate, '') != '' THEN DATEADD(DAY, ISNULL(CT.NetDays,0), (CAST(WOBI.PostedDate AS DATETIME))) ELSE DATEADD(DAY, ISNULL(CT.NetDays,0), (CAST(WOBI.InvoiceDate AS DATETIME))) END AS DiscountDate,        
  -- CASE WHEN ISNULL(DATEDIFF(DAY, (CAST(WOBI.PostedDate as DATETIME) + ISNULL(CT.Days,0)), GETUTCDATE()), 0) <= 0 THEN CAST((WOBI.GrandTotal * ISNULL(p.[PercentValue],0) / 100) AS DECIMAL(10,2)) ELSE 0 END AS DiscountAvailable       
  --   FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)      
  --   LEFT JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId      
  --   LEFT JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId      
  --   LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId      
  --   INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=WOBI.CustomerId      
  --LEFT JOIN CreditTerms CT WITH (NOLOCK) ON WO.CreditTermId = CT.CreditTermsId        
  --   LEFT JOIN [Percent] p WITH(NOLOCK) ON CAST(CT.CreditTermsId as INT) = p.PercentId        
  --   INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=WOBI.CurrencyId      
  --   LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = WOBI.BillingInvoicingId AND IPT.InvoiceType=2 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
  --   INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId AND MSD.Level1Id = @legalEntityId     
  --   where WOBI.CustomerId=@CustomerId AND WOBI.InvoiceStatus = 'Invoiced'      
    
  -- UNION     
    
  --SELECT CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentId ELSE 0 END AS 'PaymentId',      
  --    CM.CustomerId,CM.CreditMemoHeaderId AS SOBillingInvoicingId,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ReceiptId ELSE 0 END AS 'ReceiptId'      
  --    ,CM.MasterCompanyId,      
  --    0 AS IsMultiplePaymentMethod,0 AS IsCheckPayment,0 AS IsWireTransfer,0 AS IsEFT,0 AS IsCCDCPayment,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.PaymentAmount  ELSE 0 END AS PaymentAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscAmount ELSE 0 END AS DiscAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DiscType ELSE 0 END AS DiscType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeAmount  ELSE 0 END AS BankFeeAmount,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.BankFeeType  ELSE 0 END AS BankFeeType,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OtherAdjustAmt  ELSE 0 END AS OtherAdjustAmt,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Reason ELSE 0 END AS Reason,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingBalance  ELSE 0 END AS RemainingBalance,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[Status]  ELSE 'Fulfilling' END AS [Status],      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedBy]  ELSE CM.CreatedBy END AS 'CreatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedBy]  ELSE CM.UpdatedBy END AS 'UpdatedBy',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[CreatedDate]  ELSE CM.CreatedDate END AS 'CreatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[UpdatedDate]  ELSE CM.UpdatedDate END AS 'UpdatedDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsActive]  ELSE CM.IsActive END AS 'IsActive',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsDeleted]  ELSE CM.IsDeleted END AS 'IsDeleted',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN ISNULL(IPT.[IsDeposite],0)  ELSE 0 END AS 'IsDeposite',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[IsTradeReceivable]  ELSE 0 END AS IsTradeReceivable,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt      
  --    ,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',    
  -- 3 AS 'InvoiceType',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.OriginalAmount ELSE     
  -- (SELECT SUM(ISNULL(CMD.AMOUNT,0)) FROM dbo.CreditMemoDetails CMD WHERE CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0) END AS 'OriginalAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.NewRemainingBal    ELSE 0 END AS 'NewRemainingBal',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DocNum    ELSE CM.CreditMemoNumber END AS DocNum,      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CurrencyCode    ELSE CASE WHEN CM.IsWorkOrder = 1 THEN WCurr.Code ELSE SCurr.Code END END AS 'CurrencyCode',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.FxRate    ELSE 0 END AS 'FxRate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.WOSONum    ELSE CM.InvoiceNumber END AS 'WOSONum',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSI    ELSE 0 END AS 'DSI',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.DSO    ELSE 0 END AS 'DSO',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AmountPastDue    ELSE 0 END AS 'AmountPastDue',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.ARBalance    ELSE 0 END AS 'ARBalance',      
  --    NULL AS 'InvDueDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditLimit    ELSE 0 END AS 'CreditLimit',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CreditTermName    ELSE '' END AS 'CreditTermName',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.LastMSLevel    ELSE MSD.LastMSLevel END AS 'LastMSLevel',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.AllMSlevels    ELSE MSD.AllMSlevels END AS 'AllMSlevels',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN @PageIndex    ELSE @PageIndex END AS 'PageIndex',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.RemainingAmount    ELSE 0 END AS 'RemainingAmount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.InvoiceDate    ELSE CM.InvoiceDate END AS 'InvoiceDate',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.Id    ELSE CM.CreditMemoHeaderId END AS 'Id',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.GLARAccount    ELSE '' END AS 'GLARAccount',      
  --    CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected',  
  --  NULL AS DiscountDate,        
  -- 0 AS DiscountAvailable   
  --   FROM [dbo].[CreditMemo] CM WITH (NOLOCK)      
  --INNER JOIN dbo.CreditMemoDetails CMD ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId AND CMD.IsDeleted = 0    
  --LEFT JOIN SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CMD.InvoiceId =  SOBI.SOBillingInvoicingId AND CMD.IsWorkOrder = 0    
  --LEFT JOIN WorkOrderBillingInvoicing WOBI ON CMD.InvoiceId =  WOBI.BillingInvoicingId AND CMD.IsWorkOrder = 1    
  --LEFT JOIN Currency WCurr WITH (NOLOCK) ON WOBI.CurrencyId = WCurr.CurrencyId      
  --LEFT JOIN Currency SCurr WITH (NOLOCK) ON SOBI.CurrencyId = SCurr.CurrencyId      
  --   LEFT JOIN  [dbo].[InvoicePayments] IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = CM.CreditMemoHeaderId AND IPT.InvoiceType=3 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex      
  --INNER JOIN dbo.RMACreditMemoManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @CMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId AND MSD.Level1Id = @legalEntityId  
  --   where CM.CustomerId=@CustomerId AND CM.Status = 'Fulfilling'    
    
     )      
     SELECT [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]      
          ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]      
          ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
          ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]      
          ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected],[DiscountDate],[DiscountAvailable] FROM CTE      
     GROUP BY [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]      
          ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]      
          ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]      
          ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]      
          ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected],[DiscountDate],[DiscountAvailable]    
    ORDER BY [Selected] DESC,[InvoiceType]    
      
  END      
 END TRY          
  BEGIN CATCH      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
              , @AdhocComments     VARCHAR(150)    = 'GetCustomerInvoicePaymentsByReceiptId'       
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceiptId, '') + ''      
              , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
              exec spLogException       
                       @DatabaseName           = @DatabaseName      
                     , @AdhocComments          = @AdhocComments      
                     , @ProcedureParameters = @ProcedureParameters      
                     , @ApplicationName        =  @ApplicationName      
                     , @ErrorLogID             = @ErrorLogID OUTPUT;      
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
              RETURN(1);      
 END CATCH      
END