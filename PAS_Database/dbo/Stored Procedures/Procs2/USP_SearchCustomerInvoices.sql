
/*************************************************************           
 ** File:   [USP_SearchCustomerInvoices]           
 ** Author:  
 ** Description: Search CustomerInvoices 
 ** Purpose:         
 ** Date:          
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1								   	Created
	2	01/31/2024    Devendra Shekh	added isperforma Flage for WO
	3	01/02/2024	  AMIT GHEDIYA		added isperforma Flage for SO
	4   02/06/2024    Devendra Shekh	UPDATE isperforma
	5   08/02/2024	  Devendra Shekh    added IsInvoicePosted flage for WO
	6   14/02/2024	  Devendra Shekh    duplicate wo for multiple MPN issue resolved
	7   15/02/2024	  AMIT GHEDIYA      added IsBilling flage for SO
	8   15/02/2024	  AMIT GHEDIYA      added DBO & NO(LOCK)
	9   19/02/2024	  Devendra Shekh    email validation issue for wo resolved
	10  20/02/2024	  Devendra Shekh    added remainingamount condition
	11  04/03/2024	  AMIT GHEDIYA      Multiple data issue in SO.
	12  14/03/2024	  Moin Bloch        added AmountPaid
	13  18/03/2024	  Moin Bloch        added exchange details in pn view
	14  21/03/2024	  Moin Bloch        added ManagementStructureId 
	15  04/05/2024	  Moin Bloch        added condtion to removed posted and closed credit memo invoices from invoice list 
	16  06/13/2024	  Devendra Shekh    not getting SO Invoices data issue resolved
	17  06/26/2024	  Moin Bloch        added condtion to removed Refund and Refund Requested credit memo invoices from invoice list 
	18  07/23/2024	  Devendra Shekh    optimized SP and Removed unnecessary commented Data
	19  11/04/2024	  Vishal Suthar		Modified to make use of new SO Part tables
	20  11/05/2024	  AMIT GHEDIYA		Update to get remaining amount for ExSO.
	21  06-03-2025    Shrey Chandegara  Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	22  19-03-2025    RAJESH GAMI		Fix the duplicate record (I added the rowNum and based on that add condition)
	23  20-03-2025    Divyesh Kathiriya	Update InvoiceDate based on Employee time zone
	24  07 May 2025   RAJESH GAMI		Added filters (FromDate ToDate)
	25  16 May 2025   HEMANT SALIYA		Corrected WO revenue same as Billing reports
	26  22 May 2025   Devendra Shekh    Added new fields InvoiceTotalAmount, RemainingTotalAmount
	27  28 May 2025   RAJESH GAMI       Corrected InvoiceAmount
	28  28 May 2025   RAJESH GAMI       Corrected Duplicate Record in SO
	30	13 Jun 2025	  RAJESH GAMI	   	Replcae the new billing invoicing table with old one (WO, SO)
	31  17 Jun 2025   Moin Bloch        Added CustomerId
	32  26 Jun 2025   RAJESH GAMI       Resovled duplicate WO Invoice while Invoice VIEW filter selection due to WorkFlowWorkORderId
	33  04 Jul 2025   RAJESH GAMI       Added IsStandardInvoicePosted In the Billing Invoicing 
	34  14 Jul 2025	  Moin Bloch        added Credit Memo
exec dbo.USP_SearchCustomerInvoices
@PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=0,@GlobalFilter=N'',@InvoiceNo=NULL,@InvoiceStatus=NULL,@InvoiceDate=NULL,
@OrderNumber=NULL,@CustomerName=NULL,@CustomerType=NULL,@InvoiceAmt=NULL,@PN=NULL,@PNDescription=NULL,@VersionNo=NULL,@QuoteNumber=NULL,
@CustomerReference=NULL,@MasterCompanyId=1,@SerialNumber=NULL,@StockType=NULL,@ViewType=N'invoice',@EmployeeId=226,@RemainingAmount=NULL,@LastMSLevel=NULL,@Status=N''
**************************************************************/ 
CREATE    PROCEDURE [dbo].[USP_SearchCustomerInvoices]
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50),  
@SortOrder int,  
@StatusID int,  
@GlobalFilter varchar(50),
@InvoiceNo	varchar(50),
@InvoiceStatus varchar(50),
@InvoiceDate datetime=null,
@OrderNumber varchar(50),
@CustomerName varchar(50),
@CustomerType varchar(50),
@InvoiceAmt decimal=null,
@PN		varchar(50),
@PNDescription varchar(50),
@VersionNo varchar(50),
@QuoteNumber	varchar(50),
@CustomerReference varchar(50),
@MasterCompanyId int,
@SerialNumber varchar(50),
@StockType varchar(50),
@ViewType varchar(10),
@EmployeeId bigint=1,
@RemainingAmount decimal=null,
@AmountPaid decimal=null,
@LastMSLevel varchar(50)=null,
@Status varchar(50)=null,
@IsUpdated BIT = NULL,
@FromDate datetime=null,
@ToDate datetime=null
AS
BEGIN
	  DECLARE @RecordFrom INT; 
	  DECLARE @ModuleID VARCHAR(500) ='12'
	  DECLARE @SOModuleID VARCHAR(500) ='17'
	  DECLARE @ExchSOModuleID VARCHAR(500) ='19'
	  DECLARE @CMMSModuleID BIGINT;
	  DECLARE @IsActive BIT = 1  
	  DECLARE @Count INT;  
	  DECLARE @InvoiceTotalAmount DECIMAL(18, 2);  
	  DECLARE @RemainingTotalAmount DECIMAL(18, 2);  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

	  DECLARE @WOInvoiceTypeId INT;
	  DECLARE @SOInvoiceTypeId INT;
	  DECLARE @EXInvoiceTypeId INT;
	  DECLARE @CMPostedStatusId INT;
	  DECLARE @ClosedCreditMemoStatus INT;
	  DECLARE @RefundedCreditMemoStatus INT;
	  DECLARE @RefundRequestedCreditMemoStatus INT;
	  DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	  DECLARE @workOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder')
	  DECLARE @salesOrderModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SalesOrder')
	  DECLARE @exchModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'ExchangeSalesOrder')
	  DECLARE @creditMemoModuleId INT = (SELECT TOP 1 ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'CreditMemo')	

	  SELECT @CMMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE UPPER(ModuleName) ='CREDITMEMOHEADER';

	  SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

	  SELECT @WOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='WorkOrder';
      SELECT @SOInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='SalesOrder';
      SELECT @EXInvoiceTypeId = [CustomerInvoiceTypeId] FROM [dbo].[CustomerInvoiceType] WITH(NOLOCK) WHERE ModuleName='Exchange';
	  SELECT @CMPostedStatusId = Id FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'POSTED';  	  
      SELECT @ClosedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'CLOSED';
	  SELECT @RefundedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUNDED';  
      SELECT @RefundRequestedCreditMemoStatus = [Id] FROM [dbo].[CreditMemoStatus] WITH(NOLOCK) WHERE UPPER([Name]) = 'REFUND REQUESTED';  
	  
	  IF @SortColumn IS NULL  
	  BEGIN  
	   SET @SortColumn = UPPER('InvoiceDate')  
	  END   
	  ELSE  
	  BEGIN   
	   SET @SortColumn = UPPER(@SortColumn)  
	  END

	  IF(@ViewType ='invoice')
	  BEGIN
		;WITH Result AS(
			SELECT WOBI.BillingInvoicingId [InvoicingId],
				   WOBI.InvoiceNo [InvoiceNo],
				   WOBI.InvoiceStatus [InvoiceStatus],
				   --WOBI.InvoiceDate [InvoiceDate],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			       ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   WO.WorkOrderNum [OrderNumber],
				   C.Name [CustomerName],				   
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [InvoiceAmt],
				   ISNULL(WOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,
				   WQ.QuoteNumber,
				   IsWorkOrder=1,
				   IsExchange=0,
				   WOBI.ReferenceId AS [ReferenceId],
				   C.CustomerId,
				   CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate,
				   ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				   WOPN.ManagementStructureId
				   ,(CASE WHEN COUNT(WOPN.ManagementStructureId) > 1 Then 'Multiple' ELse MAX(M.LastMSLevel) END) AS 'LastMSLevel'
				   ,(CASE WHEN COUNT(WOPN.ManagementStructureId) > 1 Then 'Multiple' ELse MAX(M.AllMSlevels) END) AS 'AllMSlevels'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WQ.VersionNo) END) AS 'VersionNo'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WQ.VersionNo) END) AS 'VersionNoType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustomerReference'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustomerReferenceType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse CASE WHEN ISNULL(MAX(WOPN.RevisedSerialNumber),'') = '' THEN UPPER(MAX(SL.SerialNumber)) ELSE  UPPER( MAX(WOPN.RevisedSerialNumber)) END END) AS 'SerialNumber'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse CASE WHEN ISNULL(MAX(WOPN.RevisedSerialNumber),'') = '' THEN UPPER(MAX(SL.SerialNumber)) ELSE  UPPER( MAX(WOPN.RevisedSerialNumber)) END END) AS 'SerialNumberType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartNumber) END) AS 'PN'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartNumber) END) AS 'PartNumberType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
				   	WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
				   	WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
				   	ELSE 'OEM' END) END) AS 'StockType'
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
				   	WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
				   	WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
				   	ELSE 'OEM' END) END) AS 'StockTypeType',
					@workOrderModuleId as ModuleId,
					0 AS IsStandAloneCM,
					0 AS IsCreditMemo
				FROM dbo.WorkOrder WO WITH (NOLOCK)
					JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WO.WorkOrderId 
					JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
					JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 --AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
					JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
					--AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1 
					AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 --AND ISNULL(WOBII.IsPerformaInvoice, 0) = 0
					JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
					JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
					LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
					LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID AND WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
					LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
					LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId = WOBI.BillingInvoicingId AND ISNULL(CRM.isWorkOrder, 0) = 1
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOPN.StockLineId
					LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WOBII.ItemMasterId = I.ItemMasterId  
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 AND WOBI.ModuleId =@workOrderModuleId 
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND ISNULL(WOBI.RemainingAmount,0) > 0
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      
			AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(WOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(WOBI.IsPerformaInvoice,0) = 0))
			GROUP BY	WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceStatus, WOBI.InvoiceDate, WO.WorkOrderNum, C.[Name], CT.CustomerTypeName, WOBI.GrandTotal, WOBI.RemainingAmount, WQ.QuoteNumber, WOBI.ReferenceId
						, C.CustomerId, CRM.RMAHeaderId, WOBI.IsPerformaInvoice, WOPN.ManagementStructureId
			),				
			WorkFlowData AS(  
				SELECT PC.BillingInvoicingId,MAX(WOFN.WorkFlowWorkOrderId)WorkFlowWorkOrderId, PC.ReferenceId
				FROM dbo.BillingInvoicing PC WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK)  ON PC.BillingInvoicingId = BII.BillingInvoicingId 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON BII.SubReferenceId = WOFN.WorkOrderPartNoId--WOFN.WorkFlowWorkOrderId = PC.WorkFlowWorkOrderId
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 
				--AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				GROUP BY PC.ReferenceId,PC.BillingInvoicingId--,WOFN.WorkFlowWorkOrderId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo
				FROM Result M   
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels	,
				M.CustomerReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.BillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   --SOBI.InvoiceDate [InvoiceDate],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   SO.SalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],					   
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
					   SQ.SalesOrderQuoteNumber [QuoteNumber],
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels, 
					   SOBI.ReferenceId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNo'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQ.VersionNumber) END) AS 'VersionNoType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustomerReference'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustomerReferenceType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						 WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						 WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END ) END) AS 'StockTypeType',
						 @salesOrderModuleId as ModuleId,
						 0 AS IsStandAloneCM,
						 0 AS IsCreditMemo
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId =SOBI.BillingInvoicingId --AND ISNULL(SOBII.[IsBilling], 0) != 1
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId			
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBI.IsVersionIncrease,0)=0  AND SOBI.ModuleId = @salesOrderModuleId
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND ISNULL(SOBI.RemainingAmount,0) > 0
				AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				AND (ISNULL(@IsUpdated,0) <> 1 OR (ISNULL(SOBI.IsUpdated,0) = ISNULL(@IsUpdated,0) AND ISNULL(SOBI.IsPerformaInvoice,0) = 0))
				GROUP BY	SOBI.BillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.SalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount, SQ.SalesOrderQuoteNumber
							, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ReferenceId, C.CustomerId, CRM.RMAHeaderId, SOBI.IsPerformaInvoice, SMS.EntityMSID 
						),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount, M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo
				FROM SOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo
					),
				ExchSOResult AS(
			SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   --SOBI.InvoiceDate [InvoiceDate],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   SO.ExchangeSalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],				   
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt],
				   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
				   '' as [QuoteNumber],
				   SO.CustomerReference as CustomerReference,
				   '' as CustomerReferenceType,
				   IsWorkOrder=0,IsExchange=1,
				   SMS.LastMSLevel,
				   SMS.AllMSlevels, 
				   SOBI.ExchangeSalesOrderId AS [ReferenceId],
				   C.CustomerId,0 as WorkFlowWorkOrderId,
				   1 as isRMACreate,
				   0 AS IsPerformaInvoice,
				   SMS.EntityMSID AS ManagementStructureId
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNo'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(SO.VersionNumber) END) AS 'VersionNoType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockType'
				   ,(CASE WHEN COUNT(*) OVER (PARTITION BY  SOBI.InvoiceNo,I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
					WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					ELSE 'OEM' END ) END) AS 'StockTypeType',
					@exchModuleId as ModuleId,
					0 AS IsStandAloneCM,
					0 AS IsCreditMemo
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 AND ISNULL(SOBI.GrandTotal,0) > 0	
			AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
			AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(SOBI.IsUpdated,0) = ISNULL(@IsUpdated,0))
			GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.ExchangeSalesOrderNumber, C.[Name], CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount
						, SO.CustomerReference, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ExchangeSalesOrderId, C.CustomerId, SMS.EntityMSID,I.ItemMasterId
						),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,M.PN as [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,'' as CustomerReferenceType,
				ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo
				FROM ExchSOResult M 
				GROUP BY 
				M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				M.CustomerReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo
				),

		CreditMemoResult AS(
				SELECT DISTINCT CM.[CreditMemoHeaderId] [InvoicingId],
				       UPPER(CM.[CreditMemoNumber]) [InvoiceNo],
					   UPPER(CM.[Status]) [InvoiceStatus],					   
					   CM.[CreatedDate] [InvoiceDate],					  
					   CMD.[SOWONum] [OrderNumber],			
					   UPPER(C.[Name]) [CustomerName],
					   CT.CustomerTypeName [CustomerType],					   
					   CMD.[Amount] [InvoiceAmt],
					   CMD.[Amount] [RemainingAmount],
					   0 [AmountPaid],
					   '' [QuoteNumber],
					   IsWorkOrder=0,
					   IsExchange=0,
					   MSD.LastMSLevel,
					   MSD.AllMSlevels, 
					   CM.CreditMemoHeaderId AS [ReferenceId],
					   C.CustomerId,
					   0 as WorkFlowWorkOrderId,
					   0 isRMACreate,
					   0 AS IsPerformaInvoice,
					   MSD.EntityMSID AS ManagementStructureId,
					   '' AS 'VersionNo',
					   '' AS 'VersionNoType',					   					  
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELse MAX(CMD.ReferenceNo) END) AS 'CustomerReference',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELse MAX(CMD.ReferenceNo) END) AS 'CustomerReferenceType',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELse MAX(CMD.SerialNumber) END) AS 'SerialNumber',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELse MAX(CMD.SerialNumber) END) AS 'SerialNumberType',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELSE MAX(CMD.partnumber) END) AS 'PN',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELSE MAX(CMD.partnumber) END) AS 'PartNumberType',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELSE MAX(CMD.PartDescription) END) AS 'PNDescription',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELSE MAX(CMD.PartDescription) END) AS 'PartDescriptionType',
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELSE MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						     WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					         WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					    ELSE 'OEM' END ) END) AS 'StockType'
				       ,(CASE WHEN COUNT(*) OVER (PARTITION BY  CM.[CreditMemoNumber],I.ItemMasterId) > 1 THEN 'Multiple' ELse MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						ELSE 'OEM' END ) END) AS 'StockTypeType',
					    @creditMemoModuleId as [ModuleId],
						CM.IsStandAloneCM,
						1 AS IsCreditMemo
				FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				 LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId  
				 LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			     LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			     LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
				INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = CM.ManagementStructureId
				INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON ES.Level1Id = MSL.ID
				INNER JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId 
				 LEFT JOIN [dbo].[ItemMaster] I WITH (NOLOCK) ON CMD.ItemMasterId = I.ItemMasterId  
			WHERE CM.MasterCompanyId = @MasterCompanyid
				GROUP BY CM.[CreditMemoHeaderId],CM.[CreditMemoNumber],CM.[Status],C.[Name],CT.[CustomerTypeName],CMD.[Amount],CM.[CreatedDate], 
						 CMD.[SOWONum],CMD.[ReferenceNo],MSD.[LastMSLevel],MSD.[AllMSlevels],C.[CustomerId],MSD.[EntityMSID],I.[ItemMasterId],CM.IsStandAloneCM	
			)		 
		   , FinalResult AS(
					SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt, RemainingAmount, AmountPaid ,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo	
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount, AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
				FROM ExchSOResults
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
				FROM CreditMemoResult
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo		
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM FinalResult)  
   SELECT * INTO #TempResult from  FinalResult
   WHERE (  
    (@GlobalFilter <> '' AND (  
      (InvoiceNo like '%' +@GlobalFilter+'%') OR  
      (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
      (InvoiceDate like '%' +@GlobalFilter+'%') OR  
      (OrderNumber like '%' +@GlobalFilter+'%') OR    
      (CustomerName like '%' +@GlobalFilter+'%') OR  
      (CustomerType like '%' +@GlobalFilter+'%') OR
      (PN like '%' +@GlobalFilter+'%') OR  
      (PNDescription like '%' +@GlobalFilter+'%') OR  
      (VersionNo like '%' +@GlobalFilter+'%') OR  
	  (QuoteNumber like '%' +@GlobalFilter+'%') OR  
      (CustomerReference like '%' +@GlobalFilter+'%') OR  
      (SerialNumber like '%' +@GlobalFilter+'%') OR  
      (StockType like '%' +@GlobalFilter+'%')  OR 
	  (LastMSLevel LIKE '%' +@GlobalFilter+'%') 
      ))  
     OR     
     (@GlobalFilter='' AND (IsNull(@InvoiceNo,'') ='' OR InvoiceNo like '%' + @InvoiceNo+'%') AND  
      (IsNull(@InvoiceStatus,'') ='' OR InvoiceStatus like '%' + @InvoiceStatus+'%') AND 
	  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
      (IsNull(@OrderNumber,'') ='' OR OrderNumber like '%' + @OrderNumber+'%') AND  
      (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
      (IsNull(@CustomerType,'') ='' OR CustomerType like '%' + @CustomerType+'%') AND  
      (IsNull(CAST( @InvoiceAmt as varchar),'') ='' OR Cast(InvoiceAmt as varchar) like '%' + CAST(@InvoiceAmt as varchar)+'%') AND  
	  (IsNull(CAST( @AmountPaid as varchar),'') ='' OR Cast(AmountPaid as varchar) like '%' + CAST(@AmountPaid as varchar)+'%') AND 
	  (IsNull(CAST( @RemainingAmount as varchar),'') ='' OR Cast(RemainingAmount as varchar) like '%' + CAST(@RemainingAmount as varchar)+'%') AND 
      (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
      (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
      (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND 
	  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
      (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
      (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')  AND
	  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
	  (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
	  (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
	  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%') 
      ))
				   SELECT @Count = COUNT(InvoicingId), @InvoiceTotalAmount = SUM(ISNULL(InvoiceAmt, 0)), @RemainingTotalAmount = SUM(ISNULL(RemainingAmount, 0)) FROM #TempResult   
  
				   SELECT *, @Count As NumberOfItems, @InvoiceTotalAmount AS InvoiceTotalAmount, @RemainingTotalAmount AS RemainingTotalAmount
				   FROM #TempResult  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='AmountPaid')  THEN AmountPaid END ASC,  				   
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerReference')  THEN CustomerReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='orderNumber')  THEN OrderNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='AmountPaid')  THEN AmountPaid END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY  
   END
   ELSE
   BEGIN
			;WITH Result AS(
				SELECT DISTINCT WOBI.BillingInvoicingId [InvoicingId],
				1 AS RowNum,
				WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],
				--WOBI.InvoiceDate [InvoiceDate],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],
				C.CustomerId,
				CT.CustomerTypeName [CustomerType],
				WOBII.GrandTotal [InvoiceAmt], 
				--CASE WHEN WOBI.CostPlusType = 'Flat Rate' AND ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) ELSE CASE WHEN ISNULL(WOBII.GrandTotal,0) > 0 THEN ISNULL(WOBII.GrandTotal,0) WHEN ISNULL(WOBII.SubTotal,0) > 0 THEN ISNULL(WOBII.SubTotal,0) ELSE ISNULL(WOBII.UnitPrice,0) END END [InvoiceAmt],
				ISNULL(WOBII.RemainingAmount, 0)  RemainingAmount,
				ISNULL(ISNULL(WOBII.GrandTotal,0) - ISNULL(WOBII.RemainingAmount,0),0) AmountPaid,				
				IM.partnumber [PN], 
				IM.PartDescription [PNDescription],
				WQ.VersionNo [VersionNo],
				WQ.QuoteNumber,
				WOPN.CustomerReference [CustomerReference],
				ST.SerialNumber [SerialNumber],
				ST.stocklineid,				
				CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					 ELSE 'OEM' END AS StockType,
					 IsWorkOrder=1,IsExchange=0,
					 MSD.LastMSLevel,
					 MSD.AllMSlevels,
					 WOBI.ReferenceId AS [ReferenceId],WOWF.WorkFlowWorkOrderId,
			    CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate
					 ,ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				MSD.EntityMSID AS ManagementStructureId,@workOrderModuleId as ModuleId,
				0 AS IsStandAloneCM,
				0 AS IsCreditMemo	
				FROM dbo.BillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
				--AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1 
				AND ISNULL(WOBII.IsVersionIncrease, 0) = 0 --AND ISNULL(WOBII.IsPerformaInvoice, 0) = 0
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOBII.SubReferenceId AND WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId AND ISNULL(CRM.isWorkOrder, 0) = 1
				LEFT JOIN dbo.WorkorderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = WOPN.ID AND MSD.ModuleID = @ModuleID
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.ModuleId =@workOrderModuleId 
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND ISNULL(WOBI.RemainingAmount,0) > 0
			AND WOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @WOInvoiceTypeId)      

			UNION ALL

			SELECT DISTINCT SOBI.BillingInvoicingId [InvoicingId],
				   1 AS RowNum,
				   --ROW_NUMBER() OVER (PARTITION BY SOBI.InvoiceNo,IM.ItemMasterId ORDER BY SOBI.SOBillingInvoicingId) AS RowNum,
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   SO.SalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   C.CustomerId,
				   CT.CustomerTypeName [CustomerType],
				   SUM(ISNULL(SOBII.GrandTotal,0)) [InvoiceAmt], 
				   ISNULL(SOBII.RemainingAmount, 0) RemainingAmount,
				   ISNULL(ISNULL(SOBII.GrandTotal,0) - ISNULL(SOBII.RemainingAmount,0),0) AmountPaid,						
				   IM.partnumber [PN], 
				   IM.PartDescription [PNDescription],
				   SQ.VersionNumber [VersionNo],
				   SQ.SalesOrderQuoteNumber [QuoteNumber],
				   SO.CustomerReference [CustomerReference],
				   ST.SerialNumber [SerialNumber],
				   ST.stocklineid,
				   CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					    WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					    WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					    ELSE 'OEM' END AS StockType,
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels,
					   SOBI.ReferenceId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   CASE WHEN Max(CRM.RMAHeaderId) >1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId,@salesOrderModuleId as ModuleId,
					   0 AS IsStandAloneCM,
					   0 AS IsCreditMemo	
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId AND SOPS.StocklineId = SOBII.StocklineId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBII.IsVersionIncrease,0)=0 AND SOBI.ModuleId = @salesOrderModuleId
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND ISNULL(SOBI.RemainingAmount,0) > 0
			 AND SOBI.[BillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @SOInvoiceTypeId)
				GROUP BY SOBI.BillingInvoicingId,SOBI.InvoiceNo,
					SOBI.InvoiceStatus ,SOBI.InvoiceDate,SO.SalesOrderNumber,
					C.Name ,CT.CustomerTypeName , SOBII.RemainingAmount,
					SOBI.GrandTotal ,IM.partnumber , IM.PartDescription ,
					SQ.VersionNumber,SQ.SalesOrderQuoteNumber ,SO.CustomerReference ,ST.SerialNumber,ST.stocklineid ,
					IM.IsPma,IM.IsDER,SMS.LastMSLevel,SMS.AllMSlevels, SOBI.ReferenceId, SOBI.IsPerformaInvoice,SMS.EntityMSID,IM.ItemMasterId ,SOBII.GrandTotal,C.CustomerId

			UNION ALL

				SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
					   ROW_NUMBER() OVER (PARTITION BY SOBI.InvoiceNo,IM.ItemMasterId ORDER BY SOBI.SOBillingInvoicingId) AS RowNum,
					   SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   --SOBI.InvoiceDate [InvoiceDate],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   SO.ExchangeSalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   C.CustomerId,
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   ISNULL(SOBII.GrandTotal,0) RemainingAmount,
					   0 as AmountPaid,
					   --ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,		
					   IM.partnumber [PN], 
					   IM.PartDescription [PNDescription],
					   SO.VersionNumber [VersionNo],
					   SQ.ExchangeQuoteNumber [QuoteNumber],
					   SO.CustomerReference [CustomerReference],
					   ST.SerialNumber [SerialNumber],
					   ST.stocklineid,
					   CASE WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
						 WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
						 WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
						 ELSE 'OEM' END AS StockType,
					   IsWorkOrder=0,
					   IsExchange=1,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels,
					   SOBI.ExchangeSalesOrderId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   0 isRMACreate,
					   0 IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId, @exchModuleId as ModuleId,
					   0 AS IsStandAloneCM,
					   0 AS IsCreditMemo	
				FROM [dbo].[ExchangeSalesOrderBillingInvoicing] SOBI WITH (NOLOCK)
				LEFT JOIN [dbo].[ExchangeSalesOrderBillingInvoicingItem] SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN [dbo].[ExchangeSalesOrderPart] SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN [dbo].[ExchangeSalesOrder] SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				LEFT JOIN [dbo].[ExchangeQuote] SQ WITH (NOLOCK) ON SQ.ExchangeQuoteId = SO.ExchangeQuoteId
				LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN [dbo].[ExchangeManagementStructureDetails] SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 		
				LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SOBII.ItemMasterId = IM.ItemMasterId
				WHERE SOBI.MasterCompanyId=@MasterCompanyId	
				 AND SOBII.[IsDeleted] = 0 AND ISNULL(SOBI.[GrandTotal],0) > 0	
			     AND SOBI.[SOBillingInvoicingId] NOT IN (SELECT ISNULL(CM.[InvoiceId], 0) FROM [dbo].[CreditMemo] CM WITH (NOLOCK) WHERE CM.[StatusId] IN(@CMPostedStatusId,@ClosedCreditMemoStatus,@RefundedCreditMemoStatus,@RefundRequestedCreditMemoStatus) AND CM.[InvoiceTypeId] = @EXInvoiceTypeId)
			
			UNION ALL

				SELECT DISTINCT CM.[CreditMemoHeaderId] [InvoicingId],				      
					   ROW_NUMBER() OVER (PARTITION BY CM.[CreditMemoNumber],I.ItemMasterId ORDER BY CM.CreditMemoHeaderId) AS [RowNum],
				       UPPER(CM.[CreditMemoNumber]) [InvoiceNo],
					   UPPER(CM.[Status]) [InvoiceStatus],	
					   CM.[CreatedDate] [InvoiceDate],
					   CMD.[SOWONum] [OrderNumber],									   
					   UPPER(C.[Name]) [CustomerName],
					   C.[CustomerId],
					   CT.[CustomerTypeName] [CustomerType],						   				   
					   CMD.[Amount] [InvoiceAmt],
					   CMD.[Amount] [RemainingAmount],
					   0 [AmountPaid],
					   I.[partnumber] [PN], 
					   I.[PartDescription] [PNDescription],
					   '' AS 'VersionNo',
					   '' [QuoteNumber],
					   CMD.[ReferenceNo] AS 'CustomerReference',					   
					   CMD.[SerialNumber] AS 'SerialNumber',
					   CMD.[stocklineid],
					   CASE WHEN I.[IsPma] = 1 AND I.[IsDER] = 1 THEN 'PMA&DER'
						 WHEN I.[IsPma] = 1 AND I.[IsDER] = 0 THEN 'PMA'
						 WHEN I.[IsPma] = 0 AND I.[IsDER] = 1 THEN 'DER'
						 ELSE 'OEM' END AS [StockType],
					   [IsWorkOrder]=0,
					   [IsExchange]=0,
					   MSD.[LastMSLevel],
					   MSD.[AllMSlevels], 
					   CM.[CreditMemoHeaderId] AS [ReferenceId],
					   0 AS [WorkFlowWorkOrderId],
					   0 [isRMACreate],
					   0 [IsPerformaInvoice],
					   MSD.EntityMSID AS ManagementStructureId,
					   @creditMemoModuleId as [ModuleId],
					   CM.IsStandAloneCM,
					   1 AS IsCreditMemo	
				FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
				INNER JOIN [dbo].[CreditMemoDetails] CMD WITH (NOLOCK) ON CM.CreditMemoHeaderId = CMD.CreditMemoHeaderId
				 LEFT JOIN [dbo].[Customer] C WITH (NOLOCK) ON CM.CustomerId = C.CustomerId  
				 LEFT JOIN [dbo].[CustomerType] CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
			     LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON CM.CustomerId = CF.CustomerId    
			     LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
				INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @CMMSModuleID AND MSD.ReferenceID = CM.CreditMemoHeaderId
				INNER JOIN [dbo].[EntityStructureSetup] ES WITH (NOLOCK) ON ES.EntityStructureId = CM.ManagementStructureId
				INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH (NOLOCK) ON ES.Level1Id = MSL.ID
				INNER JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON MSL.LegalEntityId = LE.LegalEntityId 
				 LEFT JOIN [dbo].[ItemMaster] I WITH (NOLOCK) ON CMD.ItemMasterId = I.ItemMasterId  
			WHERE CM.MasterCompanyId = @MasterCompanyid

			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM Result where  RowNum = 1)  
			   SELECT * INTO #TempResults from  Result
			   WHERE RowNum = 1 AND (  
			  
				(@GlobalFilter <> '' AND (  
				  (InvoiceNo like '%' +@GlobalFilter+'%') OR  
				  (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
				  (InvoiceDate like '%' +@GlobalFilter+'%') OR  
				  (OrderNumber like '%' +@GlobalFilter+'%') OR    
				  (CustomerName like '%' +@GlobalFilter+'%') OR  
				  (CustomerType like '%' +@GlobalFilter+'%') OR 
				  (PN like '%' +@GlobalFilter+'%') OR  
				  (PNDescription like '%' +@GlobalFilter+'%') OR  
				  (VersionNo like '%' +@GlobalFilter+'%') OR 
				  (QuoteNumber like '%' +@GlobalFilter+'%') OR 
				  (CustomerReference like '%' +@GlobalFilter+'%') OR  
				  (SerialNumber like '%' +@GlobalFilter+'%') OR
				  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
				  (StockType like '%' +@GlobalFilter+'%')))  
				 OR     
				 (@GlobalFilter='' AND (IsNull(@InvoiceNo,'') ='' OR InvoiceNo like '%' + @InvoiceNo+'%') AND  
				  (IsNull(@InvoiceStatus,'') ='' OR InvoiceStatus like '%' + @InvoiceStatus+'%') AND 
				  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
				  (IsNull(@OrderNumber,'') ='' OR OrderNumber like '%' + @OrderNumber+'%') AND  
				  (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
				  (IsNull(@CustomerType,'') ='' OR CustomerType like '%' + @CustomerType+'%') AND  
				  (IsNull(CAST( @InvoiceAmt as varchar),'') ='' OR Cast(InvoiceAmt as varchar) like '%' + CAST(@InvoiceAmt as varchar)+'%') AND  
				  (IsNull(CAST( @AmountPaid as varchar),'') ='' OR Cast(AmountPaid as varchar) like '%' + CAST(@AmountPaid as varchar)+'%') AND 
				  (IsNull(CAST( @RemainingAmount as varchar),'') ='' OR Cast(RemainingAmount as varchar) like '%' + CAST(@RemainingAmount as varchar)+'%') AND 
				  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
				  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
				  (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND   
				  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND   
				  (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
				  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
				  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') and
				  (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')   AND
				 (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
				 (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
				  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%')
				  ))
				   SELECT @Count = COUNT(InvoicingId), @InvoiceTotalAmount = SUM(ISNULL(InvoiceAmt, 0)), @RemainingTotalAmount = SUM(ISNULL(RemainingAmount, 0)) FROM #TempResults 

				   SELECT *, @Count As NumberOfItems, @InvoiceTotalAmount AS InvoiceTotalAmount, @RemainingTotalAmount AS RemainingTotalAmount
				   FROM #TempResults  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='orderNumber')  THEN OrderNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='AmountPaid')  THEN AmountPaid END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerReference')  THEN CustomerReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
						
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNo')  THEN InvoiceNo END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='orderNumber')  THEN OrderNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceAmt')  THEN InvoiceAmt END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='AmountPaid')  THEN AmountPaid END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerReference')  THEN CustomerReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY
   END
END