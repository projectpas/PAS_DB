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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/03/2022   Vishal Suthar Fixed Management Structure binding

-- EXEC GetCustomerInvoicePaymentsByReceiptId 90,0,2
-- EXEC GetCustomerInvoicePaymentsByReceiptId 10135,0,2,11
-- EXEC GetCustomerInvoicePaymentsByReceiptId 153,0,2,24
-- EXEC GetCustomerInvoicePaymentsByReceiptId 10153,0,2,68
-- EXEC GetCustomerInvoicePaymentsByReceiptId 154,0,2,34
-- EXEC GetCustomerInvoicePaymentsByReceiptId 164,0,2,67     
**************************************************************/
CREATE PROCEDURE [dbo].[GetCustomerInvoicePaymentsByReceiptId]
@ReceiptId BIGINT = NULL,
@PageIndex int = NULL,
@Opr int = NULL,
@CustomerId BIGINT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		DECLARE @SOMSModuleID INT = 17, @WOMSModuleID INT = 12;
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
						,[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
						,INV.[CreatedBy],INV.[UpdatedBy],INV.[CreatedDate],INV.[UpdatedDate],INV.[IsActive],INV.[IsDeleted],0 AS [IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
						,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
						,[CreditLimit],[CreditTermName], CASE WHEN INV.[LastMSLevel] IS NOT NULL THEN INV.[LastMSLevel] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[LastMSLevel] ELSE MSD_WO.[LastMSLevel] END END LastMSLevel,
						CASE WHEN INV.[AllMSlevels] IS NOT NULL THEN INV.[AllMSlevels] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[AllMSlevels] ELSE MSD_WO.[AllMSlevels] END  END AllMSlevels,
						[PageIndex],
						CASE WHEN InvoiceType = 1 THEN SOBI.RemainingAmount ELSE WOBI.RemainingAmount END AS 'RemainingAmount',
						INV.[InvoiceDate],[Id],[GLARAccount]
						,CASE WHEN INV.IsDeleted = 1 THEN 0 ELSE 1 END AS 'Selected'
						FROM [dbo].[InvoicePayments] INV WITH (NOLOCK)
						LEFT JOIN SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId
						LEFT JOIN WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = INV.SOBillingInvoicingId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
						INNER JOIN dbo.WorkOrderManagementStructureDetails MSD_WO WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId
						WHERE ReceiptId = @ReceiptId AND PageIndex=@PageIndex AND INV.CustomerId=@CustomerId

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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt
						,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',1 AS 'InvoiceType',
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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected'
						FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
						INNER JOIN SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId
						INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=SO.CustomerId
						INNER JOIN CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId=SO.CreditTermId
						INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=SOBI.CurrencyId
						LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND IPT.InvoiceType=1 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
						where SOBI.CustomerId=@CustomerId AND SOBI.InvoiceStatus = 'Invoiced' AND SOBI.RemainingAmount > 0

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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected'
					FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
					LEFT JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
					LEFT JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
					LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
					INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=WOBI.CustomerId
					INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=WOBI.CurrencyId
					LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = WOBI.BillingInvoicingId AND IPT.InvoiceType=2 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId
					where WOBI.CustomerId=@CustomerId AND WOBI.InvoiceStatus = 'Invoiced' AND WOBI.RemainingAmount > 0
					)
					SELECT [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]
								  ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
								  ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
								  ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
								  ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected] FROM CTE
					GROUP BY [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]
								  ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
								  ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
								  ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
								  ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected];

		END
		IF(@Opr=3)--for view invoice list--
		BEGIN
			;WITH CTE AS(
					SELECT [PaymentId],INV.[CustomerId],INV.[SOBillingInvoicingId],[ReceiptId],INV.[MasterCompanyId],0 AS [IsMultiplePaymentMethod],0 AS [IsCheckPayment],0 AS [IsWireTransfer],0 AS [IsEFT],0 AS [IsCCDCPayment]
						,[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
						,INV.[CreatedBy],INV.[UpdatedBy],INV.[CreatedDate],INV.[UpdatedDate],INV.[IsActive],INV.[IsDeleted],0 AS [IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
						,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
						,[CreditLimit],[CreditTermName], CASE WHEN INV.[LastMSLevel] IS NOT NULL THEN INV.[LastMSLevel] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[LastMSLevel] ELSE MSD_WO.[LastMSLevel] END END LastMSLevel,
						CASE WHEN INV.[AllMSlevels] IS NOT NULL THEN INV.[AllMSlevels] ELSE CASE WHEN InvoiceType = 1 THEN MSD.[AllMSlevels] ELSE MSD_WO.[AllMSlevels] END  END AllMSlevels,
						[PageIndex],
						CASE WHEN InvoiceType = 1 THEN SOBI.RemainingAmount ELSE WOBI.RemainingAmount END AS 'RemainingAmount',
						INV.[InvoiceDate],[Id],[GLARAccount]
						,CASE WHEN INV.IsDeleted = 1 THEN 0 ELSE 1 END AS 'Selected'
						FROM [dbo].[InvoicePayments] INV WITH (NOLOCK)
						LEFT JOIN SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SOBI.SOBillingInvoicingId = INV.SOBillingInvoicingId
						LEFT JOIN WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WOBI.BillingInvoicingId = INV.SOBillingInvoicingId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on WOBI.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SOBI.SalesOrderId
						INNER JOIN dbo.WorkOrderManagementStructureDetails MSD_WO WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId
						WHERE ReceiptId = @ReceiptId AND PageIndex=@PageIndex AND INV.CustomerId=@CustomerId

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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.[TradeReceivableORMiscReceiptGLAccnt]  ELSE 0 END AS TradeReceivableORMiscReceiptGLAccnt
						,CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN IPT.CtrlNum    ELSE '' END AS 'CtrlNum',1 AS 'InvoiceType',
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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected'
						FROM SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
						INNER JOIN SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId
						INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=SO.CustomerId
						INNER JOIN CreditTerms CT WITH (NOLOCK) ON CT.CreditTermsId=SO.CreditTermId
						INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=SOBI.CurrencyId
						LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = SOBI.SOBillingInvoicingId AND IPT.InvoiceType=1 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @SOMSModuleID AND MSD.ReferenceID = SO.SalesOrderId
						where SOBI.CustomerId=@CustomerId AND SOBI.InvoiceStatus = 'Invoiced'

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
						CASE WHEN IPT.SOBillingInvoicingId IS NOT NULL THEN CASE WHEN IPT.IsDeleted = 1 THEN 0 ELSE 1 END    ELSE 0 END AS 'Selected'
					FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
					LEFT JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
					LEFT JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
					LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
					INNER JOIN CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId=WOBI.CustomerId
					INNER JOIN Currency CR WITH (NOLOCK) ON CR.CurrencyId=WOBI.CurrencyId
					LEFT JOIN InvoicePayments IPT WITH (NOLOCK) ON IPT.SOBillingInvoicingId = WOBI.BillingInvoicingId AND IPT.InvoiceType=2 AND IPT.ReceiptId = @ReceiptId AND IPT.PageIndex = @PageIndex
					INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @WOMSModuleID AND MSD.ReferenceID = wobii.WorkOrderPartId
					where WOBI.CustomerId=@CustomerId AND WOBI.InvoiceStatus = 'Invoiced'
					)
					SELECT [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]
								  ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
								  ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
								  ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
								  ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected] FROM CTE
					GROUP BY [PaymentId],[CustomerId],[SOBillingInvoicingId],[ReceiptId],[IsMultiplePaymentMethod],[IsCheckPayment],[IsWireTransfer],[IsEFT],[IsCCDCPayment]
								  ,[MasterCompanyId],[PaymentAmount],[DiscAmount],[DiscType],[BankFeeAmount],[BankFeeType],[OtherAdjustAmt],[Reason],[RemainingBalance],[Status]
								  ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsDeposite],[IsTradeReceivable],[TradeReceivableORMiscReceiptGLAccnt]
								  ,[CtrlNum],[InvoiceType],[OriginalAmount],[NewRemainingBal],[DocNum],[CurrencyCode],[FxRate],[WOSONum],[DSI],[DSO],[AmountPastDue],[ARBalance],[InvDueDate]
								  ,[CreditLimit],[CreditTermName],[LastMSLevel],[AllMSlevels],[PageIndex],[RemainingAmount],[InvoiceDate],[Id],[GLARAccount],[Selected];

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