/*************************************************************           
 ** File:   [usprpt_CustomerInvoiceReportList]           
 ** Author:   Vishal Suthar  
 ** Description: Get Data for Customer invoice report
 ** Purpose:         
 ** Date:   10-FEB-2026       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** SrNO Date			Author  			Change Description            
 ** --   --------		-------				--------------------------------          
	1	 10-FEB-2026	Vishal Suthar  		CREATED
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3	 09/July/2026	RAJESH GAMI  		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4	 20/July/2026	RAJESH GAMI  		[PN-17350] - Removed IsNonStock=0 filter(s) from SO and Exchange-SO branches (all 3 ViewType sections) so Non-Stock parts appear in customer invoice report list (WorkOrder branches untouched).
exec usprpt_CustomerInvoiceReportList @PageNumber=1,@PageSize=20,@SortColumn=N'InvoiceDate',@SortOrder=-1,@GlobalFilter=N'',@ViewType=N'Details',
@FromDate='2026-01-11 00:00:00',@ToDate='2026-02-11 00:00:00',@CustomerId=NULL,@strFilter=N'1,5,6!2,7,8,9!3,11,10!4,12,13!!!!!!',@CustomerName=NULL,
@CustomerCode=NULL,@InvoiceNum=N'',@InvoiceDate=NULL,@BaseCurrency=NULL,@Amount=NULL,@WOSONum=NULL,@CustReference=NULL,@PN=NULL,@PNDescription=NULL,
@SerialNumber=NULL,@QuoteNumber=NULL,@level1Str=NULL,@level2Str=NULL,@level3Str=NULL,@level4Str=NULL,@level5Str=NULL,@level6Str=NULL,@level7Str=NULL,
@level8Str=NULL,@level9Str=NULL,@level10Str=NULL,@EmployeeId=2,@MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [dbo].[usprpt_CustomerInvoiceReportList]
@PageNumber INT = NULL,
@PageSize INT = NULL,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@GlobalFilter varchar(50) = NULL,
@ViewType varchar(50) = NULL,
@FromDate DATETIME2 = NULL,
@ToDate DATETIME2 = NULL,
@CustomerId BIGINT = NULL,
@strFilter VARCHAR(MAX) = NULL,
@CustomerName VARCHAR(100) = NULL,
@CustomerCode VARCHAR(50) = NULL,
@InvoiceNum VARCHAR(50) = NULL,
@InvoiceDate DATETIME2 = NULL,
@InvoiceDueDate DATETIME2 = NULL,
@BaseCurrency VARCHAR(50) = NULL,
@Amount DECIMAL(18, 2) = NULL,
@WOSONum VARCHAR(50) = NULL,
@CustReference VARCHAR(100) = NULL,
@PN VARCHAR(100) = NULL,
@PNDescription VARCHAR(MAX) = NULL,
@SerialNumber VARCHAR(50) = NULL,
@QuoteNumber VARCHAR(50) = NULL,
@level1Str VARCHAR(500) = NULL,
@level2Str VARCHAR(500) = NULL,
@level3Str VARCHAR(500) = NULL,
@level4Str VARCHAR(500) = NULL,
@level5Str VARCHAR(500) = NULL,
@level6Str VARCHAR(500) = NULL,
@level7Str VARCHAR(500) = NULL,
@level8Str VARCHAR(500) = NULL,
@level9Str VARCHAR(500) = NULL,
@level10Str VARCHAR(500) = NULL,
@LastMSLevel varchar(50)=null,
@EmployeeId BIGINT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
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

		IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
		BEGIN    
			DROP TABLE #TEMPMSFilter
		END

		CREATE TABLE #TEMPMSFilter([ID] BIGINT  IDENTITY(1,1),[LevelIds] VARCHAR(MAX)); 

		INSERT INTO #TEMPMSFilter(LevelIds)	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!');

		DECLARE   
		@level1 VARCHAR(MAX) = NULL,  
		@level2 VARCHAR(MAX) = NULL,  
		@level3 VARCHAR(MAX) = NULL,  
		@level4 VARCHAR(MAX) = NULL,  
		@Level5 VARCHAR(MAX) = NULL,  
		@Level6 VARCHAR(MAX) = NULL,  
		@Level7 VARCHAR(MAX) = NULL,  
		@Level8 VARCHAR(MAX) = NULL,  
		@Level9 VARCHAR(MAX) = NULL,  
		@Level10 VARCHAR(MAX) = NULL 

		SELECT @level1 = LevelIds FROM #TEMPMSFilter WHERE ID = 1 
		SELECT @level2 = LevelIds FROM #TEMPMSFilter WHERE ID = 2 
		SELECT @level3 = LevelIds FROM #TEMPMSFilter WHERE ID = 3 
		SELECT @level4 = LevelIds FROM #TEMPMSFilter WHERE ID = 4 
		SELECT @level5 = LevelIds FROM #TEMPMSFilter WHERE ID = 5 
		SELECT @level6 = LevelIds FROM #TEMPMSFilter WHERE ID = 6 
		SELECT @level7 = LevelIds FROM #TEMPMSFilter WHERE ID = 7 
		SELECT @level8 = LevelIds FROM #TEMPMSFilter WHERE ID = 8 
		SELECT @level9 = LevelIds FROM #TEMPMSFilter WHERE ID = 9 
		SELECT @level10 = LevelIds FROM #TEMPMSFilter WHERE ID = 10

		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],
				LTZ.[Description]
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
			E.EmployeeId = @EmployeeId;

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

	  IF(@ViewType ='Details')
	  BEGIN
		;WITH Result AS(
			SELECT WOBI.BillingInvoicingId [InvoicingId],
				   WOBI.InvoiceNo [InvoiceNum],
				   WOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			       ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				   WO.WorkOrderNum [WOSONum],
				   C.Name [CustomerName],	
				   C.CustomerCode,
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [Amount],
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
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustReference'
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
					0 AS IsCreditMemo,
					(CR.Code) AS 'BaseCurrency',
					UPPER(MSL.Code) as level1,
					UPPER(M.[Level2Name]) as level2,       
					UPPER(M.[Level3Name]) as level3,       
					UPPER(M.[Level4Name]) as level4,       
					UPPER(M.[Level5Name]) as level5,       
					UPPER(M.[Level6Name]) as level6,       
					UPPER(M.[Level7Name]) as level7,       
					UPPER(M.[Level8Name]) as level8,       
					UPPER(M.[Level9Name]) as level9,       
					UPPER(M.[Level10Name])as level10,
					M.[Level1Id], 
					M.[Level2Id], 
					M.[Level3Id], 
					M.[Level4Id], 
					M.[Level5Id], 
					M.[Level6Id], 
					M.[Level7Id], 
					M.[Level8Id], 
					M.[Level9Id], 
					M.[Level10Id],
					ctm.Name AS CreditTerm
				FROM dbo.WorkOrder WO WITH (NOLOCK)
					JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WO.WorkOrderId 
					JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
					JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0
					JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId
					AND WOBII.SubReferenceId = WOPN.ID
					AND ISNULL(WOBII.IsVersionIncrease, 0) = 0
					JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
					JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
					LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
					LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID AND WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
					LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
					LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId = WOBI.BillingInvoicingId AND ISNULL(CRM.isWorkOrder, 0) = 1
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOPN.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
					LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WOBII.ItemMasterId = I.ItemMasterId
					INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId
					LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON M.[Level1Id] = MSL.ID
					LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON WOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
					LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 AND WOBI.ModuleId =@workOrderModuleId 
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND WOBI.IsActive = 1 AND WOBI.IsDeleted = 0
			AND (ISNULL(WOBI.IsPerformaInvoice,0) = 0)
			GROUP BY	WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceStatus, WOBI.InvoiceDate, WO.WorkOrderNum, C.[Name],C.CustomerCode, CT.CustomerTypeName, WOBI.GrandTotal, WOBI.RemainingAmount, WQ.QuoteNumber, WOBI.ReferenceId
						, C.CustomerId, CRM.RMAHeaderId, WOBI.IsPerformaInvoice, WOPN.ManagementStructureId, CR.Code, MSL.Code,
						M.[Level2Name], M.[Level3Name], M.[Level4Name], M.[Level5Name], M.[Level6Name], M.[Level7Name], M.[Level8Name], M.[Level9Name], M.[Level10Name],
						M.[Level1Id], M.[Level2Id], M.[Level3Id], M.[Level4Id], M.[Level5Id], M.[Level6Id], M.[Level7Id], M.[Level8Id], M.[Level9Id], M.[Level10Id], ctm.NetDays, ctm.Name
			),				
			WorkFlowData AS(  
				SELECT PC.BillingInvoicingId,MAX(WOFN.WorkFlowWorkOrderId)WorkFlowWorkOrderId, PC.ReferenceId
				FROM dbo.BillingInvoicing PC WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK)  ON PC.BillingInvoicingId = BII.BillingInvoicingId 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON BII.SubReferenceId = WOFN.WorkOrderPartNoId
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 
				GROUP BY PC.ReferenceId,PC.BillingInvoicingId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,
				M.CustReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				M.LastMSLevel,M.AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate, M.CreditTerm
				FROM Result M   
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid,PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				M.CustReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,M.CreditTerm)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.BillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNum],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
					   SO.SalesOrderNumber [WOSONum],
					   C.Name [CustomerName],		
					   C.CustomerCode,
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [Amount],
					   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
					   --SQ.SalesOrderQuoteNumber [QuoteNumber],
					   (CASE WHEN COUNT(DISTINCT SQP.SalesOrderQuoteNumber) > 1 Then 'Multiple' ELse MAX(SQP.SalesOrderQuoteNumber) END) AS 'QuoteNumber',
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels, 
					   SOBI.ReferenceId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
					   ,(CASE WHEN COUNT(DISTINCT SQP.SalesOrderQuoteNumber) > 1 Then 'Multiple' ELse MAX(SQP.VersionNumber) END) AS 'VersionNo'
					   ,(CASE WHEN COUNT(DISTINCT SQP.SalesOrderQuoteNumber) > 1 Then 'Multiple' ELse MAX(SQP.VersionNumber) END) AS 'VersionNoType'
					   ,(CASE WHEN COUNT(DISTINCT SO.CustomerReference) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustReference'
					   ,(CASE WHEN COUNT(DISTINCT SO.CustomerReference) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustomerReferenceType'
					   ,(CASE WHEN COUNT(DISTINCT ST.SerialNumber) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumber'
					   ,(CASE WHEN COUNT(DISTINCT ST.SerialNumber) > 1 Then 'Multiple' ELse MAX(ST.SerialNumber) END) AS 'SerialNumberType'
					   ,(CASE WHEN COUNT(DISTINCT I.partnumber) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PN'
					   ,(CASE WHEN COUNT(DISTINCT I.partnumber) > 1 Then 'Multiple' ELse MAX(I.partnumber) END) AS 'PartNumberType'
					   ,(CASE WHEN COUNT(DISTINCT I.PartDescription) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PNDescription'
					   ,(CASE WHEN COUNT(DISTINCT I.PartDescription) > 1 Then 'Multiple' ELse MAX(I.PartDescription) END) AS 'PartDescriptionType'
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
						 0 AS IsCreditMemo,
						 (CR.Code) AS 'BaseCurrency',
						 UPPER(MSL.Code) as level1,
						UPPER(SMS.[Level2Name]) as level2,       
						UPPER(SMS.[Level3Name]) as level3,       
						UPPER(SMS.[Level4Name]) as level4,       
						UPPER(SMS.[Level5Name]) as level5,       
						UPPER(SMS.[Level6Name]) as level6,       
						UPPER(SMS.[Level7Name]) as level7,       
						UPPER(SMS.[Level8Name]) as level8,       
						UPPER(SMS.[Level9Name]) as level9,       
						UPPER(SMS.[Level10Name])as level10,
						SMS.[Level1Id], 
						SMS.[Level2Id], 
						SMS.[Level3Id], 
						SMS.[Level4Id], 
						SMS.[Level5Id], 
						SMS.[Level6Id], 
						SMS.[Level7Id], 
						SMS.[Level8Id], 
						SMS.[Level9Id], 
						SMS.[Level10Id],
						ctm.Name AS CreditTerm
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId =SOBI.BillingInvoicingId --AND ISNULL(SOBII.[IsBilling], 0) != 1
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId			
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.SalesOrderQuotePartV1 SQPart WITH (NOLOCK) ON SQPart.SalesOrderQuotePartId = SOPN.SalesOrderQuotePartId
				LEFT JOIN dbo.SalesOrderQuote SQP WITH (NOLOCK) ON SQP.SalesOrderQuoteId = SQPart.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON SMS.[Level1Id] = MSL.ID
				LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON SOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBI.IsVersionIncrease,0)=0  AND SOBI.ModuleId = @salesOrderModuleId
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
				AND (ISNULL(SOBI.IsPerformaInvoice,0) = 0)
				GROUP BY	SOBI.BillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.SalesOrderNumber, C.[Name],C.CustomerCode, CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount--, SQP.SalesOrderQuoteNumber
							, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ReferenceId, C.CustomerId, CRM.RMAHeaderId, SOBI.IsPerformaInvoice, SMS.EntityMSID, CR.Code, MSL.Code,
							SMS.[Level2Name], SMS.[Level3Name], SMS.[Level4Name], SMS.[Level5Name], SMS.[Level6Name], SMS.[Level7Name], SMS.[Level8Name], SMS.[Level9Name], SMS.[Level10Name],
							SMS.[Level1Id], SMS.[Level2Id], SMS.[Level3Id], SMS.[Level4Id], SMS.[Level5Id], SMS.[Level6Id], SMS.[Level7Id], SMS.[Level8Id], SMS.[Level9Id], SMS.[Level10Id], ctm.NetDays, ctm.Name
						),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount, M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, level1,level2,level3,level4,level5,level6,level7,level8,level9,level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,M.CreditTerm
				FROM SOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,M.CreditTerm
					),
				ExchSOResult AS(
			SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNum],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				   SO.ExchangeSalesOrderNumber [WOSONum],
				   C.Name [CustomerName],
				   C.CustomerCode,
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [Amount],
				   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
				   '' as [QuoteNumber],
				   SO.CustomerReference as CustReference,
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
					0 AS IsCreditMemo,
					(CR.Code) AS 'BaseCurrency',
					UPPER(MSL.Code) as level1,
					UPPER(SMS.[Level2Name]) as level2,       
					UPPER(SMS.[Level3Name]) as level3,       
					UPPER(SMS.[Level4Name]) as level4,       
					UPPER(SMS.[Level5Name]) as level5,       
					UPPER(SMS.[Level6Name]) as level6,       
					UPPER(SMS.[Level7Name]) as level7,       
					UPPER(SMS.[Level8Name]) as level8,       
					UPPER(SMS.[Level9Name]) as level9,       
					UPPER(SMS.[Level10Name])as level10,
					SMS.[Level1Id], 
					SMS.[Level2Id], 
					SMS.[Level3Id], 
					SMS.[Level4Id], 
					SMS.[Level5Id], 
					SMS.[Level6Id], 
					SMS.[Level7Id], 
					SMS.[Level8Id], 
					SMS.[Level9Id], 
					SMS.[Level10Id],
					ctm.Name AS CreditTerm
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON SMS.[Level1Id] = MSL.ID
				LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON SOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 
			AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
			AND ISNULL(SOBI.GrandTotal, 0) > 0
			GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.ExchangeSalesOrderNumber, C.[Name],C.CustomerCode, CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount
						, SO.CustomerReference, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ExchangeSalesOrderId, C.CustomerId, SMS.EntityMSID,I.ItemMasterId, CR.Code, MSL.Code,
						SMS.[Level2Name], SMS.[Level3Name], SMS.[Level4Name], SMS.[Level5Name], SMS.[Level6Name], SMS.[Level7Name], SMS.[Level8Name], SMS.[Level9Name], SMS.[Level10Name],
						SMS.[Level1Id], SMS.[Level2Id], SMS.[Level3Id], SMS.[Level4Id], SMS.[Level5Id], SMS.[Level6Id], SMS.[Level7Id], SMS.[Level8Id], SMS.[Level9Id], SMS.[Level10Id], ctm.NetDays, ctm.Name
						),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid,M.PN as [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels, level1,level2,level3,level4,level5,level6,level7,level8,level9,level10, M.ReferenceId, 
				M.CustReference,'' as CustomerReferenceType,
				ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,M.CreditTerm
				FROM ExchSOResult M 
				GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, level1,level2,level3,level4,level5,level6,level7,level8,level9,level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,M.CreditTerm
				),

		CreditMemoResult AS(
				SELECT DISTINCT CM.[CreditMemoHeaderId] [InvoicingId],
				       UPPER(CM.[CreditMemoNumber]) [InvoiceNum],
					   UPPER(CM.[Status]) [InvoiceStatus],					   
					   CM.[CreatedDate] [InvoiceDate],
					   DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(CM.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CM.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(CM.[CreatedDate] AS DATETIME)) END) as InvoiceDueDate,
					   CMD.[SOWONum] [WOSONum],			
					   UPPER(C.[Name]) [CustomerName],
					   C.CustomerCode,
					   CT.CustomerTypeName [CustomerType],					   
					   CMD.[Amount] [Amount],
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
					   MAX(CMD.ReferenceNo) AS 'CustReference',
					   MAX(CMD.ReferenceNo) AS 'CustomerReferenceType',
					   MAX(CMD.SerialNumber) AS 'SerialNumber',
					   MAX(CMD.SerialNumber) AS 'SerialNumberType',
					   MAX(CMD.partnumber) AS 'PN',
					   MAX(CMD.partnumber) AS 'PartNumberType',
					   MAX(CMD.PartDescription) AS 'PNDescription',
					   MAX(CMD.PartDescription) AS 'PartDescriptionType',
					   MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						     WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
					         WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
					    ELSE 'OEM' END ) AS 'StockType'
				       ,MAX(CASE WHEN I.IsPma = 1 and I.IsDER = 1 THEN 'PMA&DER'
						WHEN I.IsPma = 1 and I.IsDER = 0 THEN 'PMA'
						WHEN I.IsPma = 0 and I.IsDER = 1 THEN 'DER'
						ELSE 'OEM' END ) AS 'StockTypeType',
					    @creditMemoModuleId as [ModuleId],
						CM.IsStandAloneCM,
						1 AS IsCreditMemo,
						'' AS 'BaseCurrency',
						UPPER(MNSL.Code) as level1,
						UPPER(MSD.[Level2Name]) as level2,       
						UPPER(MSD.[Level3Name]) as level3,       
						UPPER(MSD.[Level4Name]) as level4,       
						UPPER(MSD.[Level5Name]) as level5,       
						UPPER(MSD.[Level6Name]) as level6,       
						UPPER(MSD.[Level7Name]) as level7,       
						UPPER(MSD.[Level8Name]) as level8,       
						UPPER(MSD.[Level9Name]) as level9,       
						UPPER(MSD.[Level10Name])as level10,
						MSD.[Level1Id], 
						MSD.[Level2Id], 
						MSD.[Level3Id], 
						MSD.[Level4Id], 
						MSD.[Level5Id], 
						MSD.[Level6Id], 
						MSD.[Level7Id], 
						MSD.[Level8Id], 
						MSD.[Level9Id], 
						MSD.[Level10Id],
						ctm.Name AS CreditTerm
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
				 LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON MSD.[Level1Id] = MNSL.ID
			WHERE CM.MasterCompanyId = @MasterCompanyid AND CM.IsActive = 1 AND CM.IsDeleted = 0
				GROUP BY CM.[CreditMemoHeaderId],CM.[CreditMemoNumber],CM.[Status],C.[Name],C.CustomerCode, CT.[CustomerTypeName],CMD.[Amount],CM.[CreatedDate], 
						 CMD.[SOWONum],CMD.[ReferenceNo],MSD.[LastMSLevel],MSD.[AllMSlevels],C.[CustomerId],MSD.[EntityMSID],I.[ItemMasterId],CM.IsStandAloneCM,MNSL.Code,
						 MSD.[Level2Name], MSD.[Level3Name], MSD.[Level4Name], MSD.[Level5Name], MSD.[Level6Name], MSD.[Level7Name], MSD.[Level8Name], MSD.[Level9Name], MSD.[Level10Name],
						 MSD.[Level1Id], MSD.[Level2Id], MSD.[Level3Id], MSD.[Level4Id], MSD.[Level5Id], MSD.[Level6Id], MSD.[Level7Id], MSD.[Level8Id], MSD.[Level9Id], MSD.[Level10Id], CTM.NetDays, ctm.Name
			)		 
		   , FinalResult AS(
					SELECT InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount, RemainingAmount, AmountPaid ,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount, AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate, CreditTerm
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
				FROM ExchSOResults
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
				FROM CreditMemoResult
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,level1,level2,level3,level4,level5,level6,level7,level8,level9,level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate,CreditTerm
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM FinalResult)  
   SELECT * INTO #TempResult from  FinalResult
   WHERE (  
    (@GlobalFilter <> '' AND (  
      (InvoiceNum like '%' +@GlobalFilter+'%') OR  
      (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
      (InvoiceDate like '%' +@GlobalFilter+'%') OR  
      (WOSONum like '%' +@GlobalFilter+'%') OR    
      (CustomerName like '%' +@GlobalFilter+'%') OR  
      (CustomerType like '%' +@GlobalFilter+'%') OR
      (PN like '%' +@GlobalFilter+'%') OR  
      (PNDescription like '%' +@GlobalFilter+'%') OR  
      (VersionNo like '%' +@GlobalFilter+'%') OR  
	  (QuoteNumber like '%' +@GlobalFilter+'%') OR  
      (CustReference like '%' +@GlobalFilter+'%') OR  
      (SerialNumber like '%' +@GlobalFilter+'%') OR  
      (StockType like '%' +@GlobalFilter+'%')  OR 
	  (LastMSLevel LIKE '%' +@GlobalFilter+'%') 
      ))  
     OR     
     (@GlobalFilter='' AND (IsNull(@InvoiceNum,'') ='' OR InvoiceNum like '%' + @InvoiceNum+'%') AND  
	  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
      (IsNull(@WOSONum,'') ='' OR WOSONum like '%' + @WOSONum+'%') AND  
      (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
      (IsNull(CAST( @Amount as varchar),'') ='' OR Cast(Amount as varchar) like '%' + CAST(@Amount as varchar)+'%') AND  
      (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
      (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
	  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
      (IsNull(@CustReference,'') ='' OR CustReference like '%' + @CustReference+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
	  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
	  (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
	  (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
	   (1=1)
				))
				   SELECT @Count = COUNT(InvoicingId), @InvoiceTotalAmount = SUM(ISNULL(Amount, 0)), @RemainingTotalAmount = SUM(ISNULL(RemainingAmount, 0)) FROM #TempResult   
  
				   SELECT *, @Count As NumberOfItems, @InvoiceTotalAmount AS InvoiceTotalAmount, @RemainingTotalAmount AS RemainingTotalAmount
				   FROM #TempResult  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='WOSONum')  THEN WOSONum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='Amount')  THEN Amount END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='AmountPaid')  THEN AmountPaid END ASC,  				   
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustReference')  THEN CustReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='WOSONum')  THEN WOSONum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='Amount')  THEN Amount END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='AmountPaid')  THEN AmountPaid END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustReference')  THEN CustReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY  
	  END
	  ELSE IF(@ViewType ='InvoiceDate')
	  BEGIN
		;WITH Result AS(
			SELECT WOBI.BillingInvoicingId [InvoicingId],
				   WOBI.InvoiceNo [InvoiceNum],
				   WOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			       ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				   WO.WorkOrderNum [WOSONum],
				   C.Name [CustomerName],	
				   C.CustomerCode,
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [Amount],
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
				   ,(CASE WHEN COUNT(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(WOPN.CustomerReference) END) AS 'CustReference'
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
					0 AS IsCreditMemo,
					(CR.Code) AS 'BaseCurrency',
					UPPER(MSL.Code) as level1,
					UPPER(M.[Level2Name]) as level2,       
					UPPER(M.[Level3Name]) as level3,       
					UPPER(M.[Level4Name]) as level4,       
					UPPER(M.[Level5Name]) as level5,       
					UPPER(M.[Level6Name]) as level6,       
					UPPER(M.[Level7Name]) as level7,       
					UPPER(M.[Level8Name]) as level8,       
					UPPER(M.[Level9Name]) as level9,       
					UPPER(M.[Level10Name])as level10,
					M.[Level1Id], 
					M.[Level2Id], 
					M.[Level3Id], 
					M.[Level4Id], 
					M.[Level5Id], 
					M.[Level6Id], 
					M.[Level7Id], 
					M.[Level8Id], 
					M.[Level9Id], 
					M.[Level10Id]
				FROM dbo.WorkOrder WO WITH (NOLOCK)
					JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WO.WorkOrderId 
					JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
					JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.ReferenceId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0
					JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
					AND WOBII.SubReferenceId = WOPN.ID
					AND ISNULL(WOBII.IsVersionIncrease, 0) = 0
					JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
					JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
					LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
					LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID AND WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
					LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId = CT.CustomerTypeId
					LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId = WOBI.BillingInvoicingId AND ISNULL(CRM.isWorkOrder, 0) = 1
					LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = WOPN.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
					LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On WOBII.ItemMasterId = I.ItemMasterId
					INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = WOBI.CurrencyId
					LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON M.[Level1Id] = MSL.ID
					LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON WOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
					LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease,0) = 0 AND WOBI.ModuleId =@workOrderModuleId 
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND WOBI.IsActive = 1 AND WOBI.IsDeleted = 0
			AND (ISNULL(WOBI.IsPerformaInvoice,0) = 0)
			GROUP BY	WOBI.BillingInvoicingId, WOBI.InvoiceNo, WOBI.InvoiceStatus, WOBI.InvoiceDate, WO.WorkOrderNum, C.[Name],C.CustomerCode, CT.CustomerTypeName, WOBI.GrandTotal, WOBI.RemainingAmount, WQ.QuoteNumber, WOBI.ReferenceId
						, C.CustomerId, CRM.RMAHeaderId, WOBI.IsPerformaInvoice, WOPN.ManagementStructureId, CR.Code, MSL.Code,
						M.[Level2Name], M.[Level3Name], M.[Level4Name], M.[Level5Name], M.[Level6Name], M.[Level7Name], M.[Level8Name], M.[Level9Name], M.[Level10Name],
						M.[Level1Id], M.[Level2Id], M.[Level3Id], M.[Level4Id], M.[Level5Id], M.[Level6Id], M.[Level7Id], M.[Level8Id], M.[Level9Id], M.[Level10Id], ctm.NetDays
			),				
			WorkFlowData AS(  
				SELECT PC.BillingInvoicingId,MAX(WOFN.WorkFlowWorkOrderId)WorkFlowWorkOrderId, PC.ReferenceId
				FROM dbo.BillingInvoicing PC WITH (NOLOCK) 
				INNER JOIN dbo.BillingInvoicingItems BII WITH (NOLOCK)  ON PC.BillingInvoicingId = BII.BillingInvoicingId 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON BII.SubReferenceId = WOFN.WorkOrderPartNoId
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 
				GROUP BY PC.ReferenceId,PC.BillingInvoicingId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,
				M.CustReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10
				FROM Result M   
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid,PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				M.CustReference,M.CustomerReferenceType,M.SerialNumber,M.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.BillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNum],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
					   SO.SalesOrderNumber [WOSONum],
					   C.Name [CustomerName],		
					   C.CustomerCode,
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [Amount],
					   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
					   --SQ.SalesOrderQuoteNumber [QuoteNumber],
					   (CASE WHEN COUNT(DISTINCT SQP.SalesOrderQuoteNumber) > 1 Then 'Multiple' ELse MAX(SQP.SalesOrderQuoteNumber) END) AS 'QuoteNumber',
					   IsWorkOrder=0,
					   IsExchange=0,
					   SMS.LastMSLevel,
					   SMS.AllMSlevels, 
					   SOBI.ReferenceId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQP.VersionNumber) END) AS 'VersionNo'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQP.VersionNumber) END) AS 'VersionNoType'
					   ,(CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SO.CustomerReference) END) AS 'CustReference'
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
						 0 AS IsCreditMemo,
						 (CR.Code) AS 'BaseCurrency',
						 UPPER(MSL.Code) as level1,
						UPPER(SMS.[Level2Name]) as level2,       
						UPPER(SMS.[Level3Name]) as level3,       
						UPPER(SMS.[Level4Name]) as level4,       
						UPPER(SMS.[Level5Name]) as level5,       
						UPPER(SMS.[Level6Name]) as level6,       
						UPPER(SMS.[Level7Name]) as level7,       
						UPPER(SMS.[Level8Name]) as level8,       
						UPPER(SMS.[Level9Name]) as level9,       
						UPPER(SMS.[Level10Name])as level10,
						SMS.[Level1Id], 
						SMS.[Level2Id], 
						SMS.[Level3Id], 
						SMS.[Level4Id], 
						SMS.[Level5Id], 
						SMS.[Level6Id], 
						SMS.[Level7Id], 
						SMS.[Level8Id], 
						SMS.[Level9Id], 
						SMS.[Level10Id]
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId =SOBI.BillingInvoicingId --AND ISNULL(SOBII.[IsBilling], 0) != 1
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId			
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.SalesOrderQuotePartV1 SQPart WITH (NOLOCK) ON SQPart.SalesOrderQuotePartId = SOPN.SalesOrderQuotePartId
				LEFT JOIN dbo.SalesOrderQuote SQP WITH (NOLOCK) ON SQP.SalesOrderQuoteId = SQPart.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON SMS.[Level1Id] = MSL.ID
				LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON SOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBI.IsVersionIncrease,0)=0  AND SOBI.ModuleId = @salesOrderModuleId
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
				AND (ISNULL(SOBI.IsPerformaInvoice,0) = 0)
				GROUP BY	SOBI.BillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.SalesOrderNumber, C.[Name],C.CustomerCode, CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount--, SQ.SalesOrderQuoteNumber
							, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ReferenceId, C.CustomerId, CRM.RMAHeaderId, SOBI.IsPerformaInvoice, SMS.EntityMSID, CR.Code, MSL.Code,
							SMS.[Level2Name], SMS.[Level3Name], SMS.[Level4Name], SMS.[Level5Name], SMS.[Level6Name], SMS.[Level7Name], SMS.[Level8Name], SMS.[Level9Name], SMS.[Level10Name],
							SMS.[Level1Id], SMS.[Level2Id], SMS.[Level3Id], SMS.[Level4Id], SMS.[Level5Id], SMS.[Level6Id], SMS.[Level7Id], SMS.[Level8Id], SMS.[Level9Id], SMS.[Level10Id], ctm.NetDays
						),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount, M.AmountPaid, M.PN [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate
				FROM SOResult M   
				GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate
					),
				ExchSOResult AS(
			SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNum],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   DATEADD(DAY, ctm.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				   SO.ExchangeSalesOrderNumber [WOSONum],
				   C.Name [CustomerName],
				   C.CustomerCode,
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [Amount],
				   ISNULL(SOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
				   '' as [QuoteNumber],
				   SO.CustomerReference as CustReference,
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
					0 AS IsCreditMemo,
					(CR.Code) AS 'BaseCurrency',
					UPPER(MSL.Code) as level1,
					UPPER(SMS.[Level2Name]) as level2,       
					UPPER(SMS.[Level3Name]) as level3,       
					UPPER(SMS.[Level4Name]) as level4,       
					UPPER(SMS.[Level5Name]) as level5,       
					UPPER(SMS.[Level6Name]) as level6,       
					UPPER(SMS.[Level7Name]) as level7,       
					UPPER(SMS.[Level8Name]) as level8,       
					UPPER(SMS.[Level9Name]) as level9,       
					UPPER(SMS.[Level10Name])as level10,
					SMS.[Level1Id], 
					SMS.[Level2Id], 
					SMS.[Level3Id], 
					SMS.[Level4Id], 
					SMS.[Level5Id], 
					SMS.[Level6Id], 
					SMS.[Level7Id], 
					SMS.[Level8Id], 
					SMS.[Level9Id], 
					SMS.[Level10Id]
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
				LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On SOBII.ItemMasterId=I.ItemMasterId
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON SMS.[Level1Id] = MSL.ID
				LEFT JOIN  [dbo].[CustomerFinancial] cf WITH(NOLOCK) ON SOBI.CustomerId = cf.CustomerId AND ISNULL(cf.IsDeleted,0) = 0
				LEFT JOIN  [dbo].[CreditTerms] ctm WITH(NOLOCK) ON cf.CreditTermsId = ctm.CreditTermsId
			WHERE SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 
			AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
			AND ISNULL(SOBI.GrandTotal, 0) > 0
			GROUP BY	SOBI.SOBillingInvoicingId, SOBI.InvoiceNo, SOBI.InvoiceStatus, SOBI.InvoiceDate, SO.ExchangeSalesOrderNumber, C.[Name],C.CustomerCode, CT.CustomerTypeName, SOBI.GrandTotal, SOBI.RemainingAmount
						, SO.CustomerReference, SMS.LastMSLevel, SMS.AllMSlevels, SOBI.ExchangeSalesOrderId, C.CustomerId, SMS.EntityMSID,I.ItemMasterId, CR.Code, MSL.Code,
						SMS.[Level2Name], SMS.[Level3Name], SMS.[Level4Name], SMS.[Level5Name], SMS.[Level6Name], SMS.[Level7Name], SMS.[Level8Name], SMS.[Level9Name], SMS.[Level10Name],
						SMS.[Level1Id], SMS.[Level2Id], SMS.[Level3Id], SMS.[Level4Id], SMS.[Level5Id], SMS.[Level6Id], SMS.[Level7Id], SMS.[Level8Id], SMS.[Level9Id], SMS.[Level10Id], ctm.NetDays
						),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid,M.PN as [PN],M.PNDescription [PNDescription],
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, M.ReferenceId, 
				M.CustReference,'' as CustomerReferenceType,
				ISNULL(M.SerialNumber,'') [SerialNumber],M.IsWorkOrder,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate
				FROM ExchSOResult M 
				GROUP BY 
				M.InvoicingId,M.InvoiceNum,M.InvoiceStatus,M.InvoiceDate,M.WOSONum,
				M.CustomerName,M.CustomerCode,M.CustomerType,M.Amount,M.RemainingAmount,M.AmountPaid, PN,M.PNDescription,
				M.PartNumberType,M.PartDescriptionType,M.StockType,M.StocktypeType,
				M.VersionNo,M.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, M.ReferenceId, 
				M.CustReference,ISNULL(M.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,M.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId,M.ModuleId,M.IsStandAloneCM,M.IsCreditMemo,M.BaseCurrency,M.InvoiceDueDate
				),

		CreditMemoResult AS(
				SELECT DISTINCT CM.[CreditMemoHeaderId] [InvoicingId],
				       UPPER(CM.[CreditMemoNumber]) [InvoiceNum],
					   UPPER(CM.[Status]) [InvoiceStatus],					   
					   CM.[CreatedDate] [InvoiceDate],
					   DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(CM.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CM.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(CM.[CreatedDate] AS DATETIME)) END) as InvoiceDueDate,
					   CMD.[SOWONum] [WOSONum],			
					   UPPER(C.[Name]) [CustomerName],
					   C.CustomerCode,
					   CT.CustomerTypeName [CustomerType],					   
					   CMD.[Amount] [Amount],
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
					   (CASE WHEN COUNT(CMD.CreditMemoDetailId) > 1 Then 'Multiple' ELse MAX(CMD.ReferenceNo) END) AS 'CustReference',
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
						1 AS IsCreditMemo,
						'' AS 'BaseCurrency',
						UPPER(MNSL.Code) as level1,
						UPPER(MSD.[Level2Name]) as level2,       
						UPPER(MSD.[Level3Name]) as level3,       
						UPPER(MSD.[Level4Name]) as level4,       
						UPPER(MSD.[Level5Name]) as level5,       
						UPPER(MSD.[Level6Name]) as level6,       
						UPPER(MSD.[Level7Name]) as level7,       
						UPPER(MSD.[Level8Name]) as level8,       
						UPPER(MSD.[Level9Name]) as level9,       
						UPPER(MSD.[Level10Name])as level10,
						MSD.[Level1Id], 
						MSD.[Level2Id], 
						MSD.[Level3Id], 
						MSD.[Level4Id], 
						MSD.[Level5Id], 
						MSD.[Level6Id], 
						MSD.[Level7Id], 
						MSD.[Level8Id], 
						MSD.[Level9Id], 
						MSD.[Level10Id]
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
				 LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON MSD.[Level1Id] = MNSL.ID
			WHERE CM.MasterCompanyId = @MasterCompanyid AND CM.IsActive = 1 AND CM.IsDeleted = 0
				GROUP BY CM.[CreditMemoHeaderId],CM.[CreditMemoNumber],CM.[Status],C.[Name],C.CustomerCode, CT.[CustomerTypeName],CMD.[Amount],CM.[CreatedDate], 
						 CMD.[SOWONum],CMD.[ReferenceNo],MSD.[LastMSLevel],MSD.[AllMSlevels],C.[CustomerId],MSD.[EntityMSID],I.[ItemMasterId],CM.IsStandAloneCM,MNSL.Code,
						 MSD.[Level2Name], MSD.[Level3Name], MSD.[Level4Name], MSD.[Level5Name], MSD.[Level6Name], MSD.[Level7Name], MSD.[Level8Name], MSD.[Level9Name], MSD.[Level10Name],
						 MSD.[Level1Id], MSD.[Level2Id], MSD.[Level3Id], MSD.[Level4Id], MSD.[Level5Id], MSD.[Level6Id], MSD.[Level7Id], MSD.[Level8Id], MSD.[Level9Id], MSD.[Level10Id], CTM.NetDays
			)		 
		   , FinalResult AS(
					SELECT InvoicingId,InvoiceNum,InvoiceStatus,CAST(InvoiceDate AS DATE) AS InvoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount, RemainingAmount, AmountPaid ,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount, AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,CAST(InvoiceDate AS DATE) AS InvoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,CAST(InvoiceDate AS DATE) AS InvoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
				FROM ExchSOResults
					UNION ALL 
				SELECT InvoicingId,InvoiceNum,InvoiceStatus,CAST(InvoiceDate AS DATE) AS InvoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
				FROM CreditMemoResult
				GROUP BY 
				InvoicingId,InvoiceNum,InvoiceStatus,invoiceDate,WOSONum,
				CustomerName,CustomerCode,CustomerType,Amount,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				level1, level2, level3, level4, level5, level6, level7, level8, level9, level10,
				CustReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId,ModuleId,IsStandAloneCM,IsCreditMemo,BaseCurrency,InvoiceDueDate		
			),
			FinalResults AS (
				SELECT 0 as totalAmount,
				R.* 
				FROM FinalResult R 
				WHERE (  
					(@GlobalFilter <> '' AND (  
					  (InvoiceNum like '%' +@GlobalFilter+'%') OR  
					  (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
					  (InvoiceDate like '%' +@GlobalFilter+'%') OR  
					  (WOSONum like '%' +@GlobalFilter+'%') OR    
					  (CustomerName like '%' +@GlobalFilter+'%') OR  
					  (CustomerType like '%' +@GlobalFilter+'%') OR
					  (PN like '%' +@GlobalFilter+'%') OR  
					  (PNDescription like '%' +@GlobalFilter+'%') OR  
					  (VersionNo like '%' +@GlobalFilter+'%') OR  
					  (QuoteNumber like '%' +@GlobalFilter+'%') OR  
					  (CustReference like '%' +@GlobalFilter+'%') OR  
					  (SerialNumber like '%' +@GlobalFilter+'%') OR  
					  (StockType like '%' +@GlobalFilter+'%')  OR 
					  (LastMSLevel LIKE '%' +@GlobalFilter+'%') 
					  ))  
					 OR     
					 (@GlobalFilter='' AND (IsNull(@InvoiceNum,'') ='' OR InvoiceNum like '%' + @InvoiceNum+'%') AND  
					  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
					  (IsNull(@WOSONum,'') ='' OR WOSONum like '%' + @WOSONum+'%') AND  
					  (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
					  (IsNull(CAST( @Amount as varchar),'') ='' OR Cast(Amount as varchar) like '%' + CAST(@Amount as varchar)+'%') AND  
					  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
					  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
					  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
					  (IsNull(@CustReference,'') ='' OR CustReference like '%' + @CustReference+'%') AND  
					  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
					  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
					  (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
					  (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
					   (1=1)
				))
			),
			InvoiceDateWiseResult AS
				(
					SELECT
						CAST(InvoiceDate AS DATE) AS InvoiceDate,
						CASE 
							WHEN COUNT(DISTINCT CustomerName) > 1 
								THEN 'Multiple'
							ELSE MAX(CustomerName)
						END AS CustomerName,

						SUM(Amount) AS amount,

						CASE 
							WHEN COUNT(DISTINCT InvoiceNum) > 1 
								THEN 'Multiple'
							ELSE MAX(InvoiceNum)
						END AS InvoiceNum,

						CASE 
							WHEN COUNT(DISTINCT InvoiceStatus) > 1 
								THEN 'Multiple'
							ELSE MAX(InvoiceStatus)
						END AS InvoiceStatus,

						CASE 
							WHEN COUNT(DISTINCT WOSONum) > 1 
								THEN 'Multiple'
							ELSE MAX(WOSONum)
						END AS WOSONum,
						CASE 
							WHEN COUNT(DISTINCT CustomerType) > 1 
								THEN 'Multiple'
							ELSE MAX(CustomerType)
						END AS CustomerType,

						CASE 
							WHEN COUNT(DISTINCT BaseCurrency) > 1 
								THEN 'Multiple'
							ELSE MAX(BaseCurrency)
						END AS BaseCurrency,

						CASE 
							WHEN COUNT(DISTINCT PN) > 1 
								THEN 'Multiple'
							ELSE MAX(PN)
						END AS PN,

						CASE 
							WHEN COUNT(DISTINCT PNDescription) > 1 
								THEN 'Multiple'
							ELSE MAX(PNDescription)
						END AS PNDescription,

						CASE 
							WHEN COUNT(DISTINCT VersionNo) > 1 
								THEN 'Multiple'
							ELSE MAX(VersionNo)
						END AS VersionNo,

						CASE 
							WHEN COUNT(DISTINCT QuoteNumber) > 1 
								THEN 'Multiple'
							ELSE MAX(QuoteNumber)
						END AS QuoteNumber,

						CASE 
							WHEN COUNT(DISTINCT CustReference) > 1 
								THEN 'Multiple'
							ELSE MAX(CustReference)
						END AS CustReference,

						CASE 
							WHEN COUNT(DISTINCT SerialNumber) > 1 
								THEN 'Multiple'
							ELSE MAX(SerialNumber)
						END AS SerialNumber,

						CASE 
							WHEN COUNT(DISTINCT StockType) > 1 
								THEN 'Multiple'
							ELSE MAX(StockType)
						END AS StockType,

						CASE 
							WHEN COUNT(DISTINCT LastMSLevel) > 1 
								THEN 'Multiple'
							ELSE MAX(LastMSLevel)
						END AS LastMSLevel,
						MAX(level1) AS level1,
						MAX(level2) AS level2,
						MAX(level3) AS level3,
						MAX(level4) AS level4,
						MAX(level5) AS level5,
						MAX(level6) AS level6,
						MAX(level7) AS level7,
						MAX(level8) AS level8,
						MAX(level9) AS level9,
						MAX(level10) AS level10
					FROM FinalResults
					WHERE InvoiceDate IS NOT NULL
					GROUP BY
						InvoiceDate
				), 
				ResultCount AS (
					SELECT COUNT(InvoiceDate) AS NumberOfItems FROM InvoiceDateWiseResult
				) 
				   SELECT * FROM InvoiceDateWiseResult, ResultCount
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='WOSONum')  THEN WOSONum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='Amount')  THEN Amount END ASC,  
				   
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustReference')  THEN CustReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='WOSONum')  THEN WOSONum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='Amount')  THEN Amount END DESC,  
				   
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustReference')  THEN CustReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY  
   END
	  ELSE IF(@ViewType ='Customer')
	  BEGIN
			;WITH Result AS(
				SELECT DISTINCT WOBI.BillingInvoicingId [InvoicingId],
				1 AS RowNum,
				WOBI.InvoiceNo [InvoiceNum],
				WOBI.InvoiceStatus [InvoiceStatus],
				CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					 CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
					CASE WHEN CAST(WOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(WOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				ELSE (CAST(WOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				WO.WorkOrderNum [WOSONum],
				C.Name [CustomerName],
				C.CustomerCode,
				C.CustomerId,
				CT.CustomerTypeName [CustomerType],
				WOBII.GrandTotal [Amount], 
				ISNULL(WOBI.RemainingAmount, 0)  RemainingAmount,
				ISNULL(ISNULL(WOBII.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,				
				IM.partnumber [PN], 
				IM.PartDescription [PNDescription],
				WQ.VersionNo [VersionNo],
				WQ.QuoteNumber,
				WOPN.CustomerReference [CustReference],
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
				0 AS IsCreditMemo,
				(CR.Code) AS 'BaseCurrency',
				UPPER(MNSL.Code) as level1,
				UPPER(MSD.[Level2Name]) as level2,       
				UPPER(MSD.[Level3Name]) as level3,       
				UPPER(MSD.[Level4Name]) as level4,       
				UPPER(MSD.[Level5Name]) as level5,       
				UPPER(MSD.[Level6Name]) as level6,       
				UPPER(MSD.[Level7Name]) as level7,       
				UPPER(MSD.[Level8Name]) as level8,       
				UPPER(MSD.[Level9Name]) as level9,       
				UPPER(MSD.[Level10Name])as level10,
				MSD.[Level1Id], 
				MSD.[Level2Id], 
				MSD.[Level3Id], 
				MSD.[Level4Id], 
				MSD.[Level5Id], 
				MSD.[Level6Id], 
				MSD.[Level7Id], 
				MSD.[Level8Id], 
				MSD.[Level9Id], 
				MSD.[Level10Id]
				FROM dbo.BillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId 
				AND ISNULL(WOBII.IsVersionIncrease, 0) = 0
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOBII.SubReferenceId AND WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ISNULL(ST.IsNonStock,0) = 0
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId AND ISNULL(CRM.isWorkOrder, 0) = 1
				LEFT JOIN dbo.WorkorderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = WOPN.ID AND MSD.ModuleID = @ModuleID
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = wobi.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON MSD.[Level1Id] = MNSL.ID
				LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON WOBI.CustomerId = CF.CustomerId    
			    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
			WHERE WOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND WOBI.ModuleId =@workOrderModuleId 
			AND ISNULL(WOBI.[IsStandardInvoicePosted], 0) != 1 
			AND WOBI.IsActive = 1 AND WOBI.IsDeleted = 0
			AND (ISNULL(WOBI.IsPerformaInvoice,0) = 0)

			UNION ALL

			SELECT DISTINCT SOBI.BillingInvoicingId [InvoicingId],
				   1 AS RowNum,
				   SOBI.InvoiceNo [InvoiceNum],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
				   DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
						CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
				   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
				   SO.SalesOrderNumber [WOSONum],
				   C.Name [CustomerName],
				   C.CustomerCode,
				   C.CustomerId,
				   CT.CustomerTypeName [CustomerType],
				   SUM(ISNULL(SOBII.GrandTotal,0)) [Amount], 
				   ISNULL(SOBI.RemainingAmount, 0) RemainingAmount,
				   ISNULL(ISNULL(SOBII.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,						
				   IM.partnumber [PN], 
				   IM.PartDescription [PNDescription],
				   (CASE WHEN COUNT(SOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse MAX(SQP.VersionNumber) END) AS 'VersionNo',
				   --SQ.SalesOrderQuoteNumber [QuoteNumber],
				   (CASE WHEN COUNT(DISTINCT SQP.SalesOrderQuoteNumber) > 1 Then 'Multiple' ELse MAX(SQP.SalesOrderQuoteNumber) END) AS 'QuoteNumber',
				   SO.CustomerReference [CustReference],
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
					   0 AS IsCreditMemo,
					   (CR.Code) AS 'BaseCurrency',
					   UPPER(MNSL.Code) as level1,
						UPPER(SMS.[Level2Name]) as level2,       
						UPPER(SMS.[Level3Name]) as level3,       
						UPPER(SMS.[Level4Name]) as level4,       
						UPPER(SMS.[Level5Name]) as level5,       
						UPPER(SMS.[Level6Name]) as level6,       
						UPPER(SMS.[Level7Name]) as level7,       
						UPPER(SMS.[Level8Name]) as level8,       
						UPPER(SMS.[Level9Name]) as level9,       
						UPPER(SMS.[Level10Name])as level10,
						SMS.[Level1Id], 
						SMS.[Level2Id], 
						SMS.[Level3Id], 
						SMS.[Level4Id], 
						SMS.[Level5Id], 
						SMS.[Level6Id], 
						SMS.[Level7Id], 
						SMS.[Level8Id], 
						SMS.[Level9Id], 
						SMS.[Level10Id]
			FROM dbo.BillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId
				LEFT JOIN dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
				LEFT JOIN dbo.SalesOrderStocklineV1 SOPS WITH (NOLOCK) ON SOPS.SalesOrderPartId = SOPN.SalesOrderPartId AND SOPS.StocklineId = SOBII.StocklineId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.SalesOrderQuotePartV1 SQPart WITH (NOLOCK) ON SQPart.SalesOrderQuotePartId = SOPN.SalesOrderQuotePartId
				LEFT JOIN dbo.SalesOrderQuote SQP WITH (NOLOCK) ON SQP.SalesOrderQuoteId = SQPart.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				 LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPS.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.BillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON SMS.[Level1Id] = MNSL.ID
				LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId    
			    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND ISNULL(SOBII.IsVersionIncrease,0)=0 AND SOBI.ModuleId = @salesOrderModuleId
			AND ISNULL(SOBI.[IsStandardInvoicePosted], 0) != 1 
			AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
			AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
				GROUP BY SOBI.BillingInvoicingId,SOBI.InvoiceNo,
					SOBI.InvoiceStatus ,SOBI.InvoiceDate,SO.SalesOrderNumber,
					C.Name ,C.CustomerCode,CT.CustomerTypeName , SOBI.RemainingAmount,
					SOBI.GrandTotal ,IM.partnumber , IM.PartDescription ,
					--SQ.VersionNumber,SQ.SalesOrderQuoteNumber,
					SO.CustomerReference ,ST.SerialNumber,ST.stocklineid ,
					IM.IsPma,IM.IsDER,SMS.LastMSLevel,SMS.AllMSlevels, SOBI.ReferenceId, SOBI.IsPerformaInvoice,SMS.EntityMSID,IM.ItemMasterId ,SOBII.GrandTotal,C.CustomerId,
					CR.Code, MNSL.Code, SMS.[Level2Name], SMS.[Level3Name], SMS.[Level4Name], SMS.[Level5Name], SMS.[Level6Name], SMS.[Level7Name], SMS.[Level8Name], SMS.[Level9Name], SMS.[Level10Name],
					SMS.[Level1Id], SMS.[Level2Id], SMS.[Level3Id], SMS.[Level4Id], SMS.[Level5Id], SMS.[Level6Id], SMS.[Level7Id], SMS.[Level8Id], SMS.[Level9Id], SMS.[Level10Id],CTM.NetDays
			UNION ALL

				SELECT DISTINCT SOBI.SOBillingInvoicingId [InvoicingId],
					   ROW_NUMBER() OVER (PARTITION BY SOBI.InvoiceNo,IM.ItemMasterId ORDER BY SOBI.SOBillingInvoicingId) AS RowNum,
					   SOBI.InvoiceNo [InvoiceNum],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END InvoiceDate,
					   DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(SOBI.InvoiceDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(SOBI.InvoiceDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(SOBI.InvoiceDate AS DATETIME)) END) as InvoiceDueDate,
					   SO.ExchangeSalesOrderNumber [WOSONum],
					   C.Name [CustomerName],
					   C.CustomerCode,
					   C.CustomerId,
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [Amount],
					   ISNULL(SOBII.GrandTotal,0) RemainingAmount,
					   0 as AmountPaid,
					   IM.partnumber [PN], 
					   IM.PartDescription [PNDescription],
					   SO.VersionNumber [VersionNo],
					   SQ.ExchangeQuoteNumber [QuoteNumber],
					   SO.CustomerReference [CustReference],
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
					   0 AS IsCreditMemo,
					   (CR.Code) AS 'BaseCurrency',
					   UPPER(MNSL.Code) as level1,
						UPPER(SMS.[Level2Name]) as level2,       
						UPPER(SMS.[Level3Name]) as level3,       
						UPPER(SMS.[Level4Name]) as level4,       
						UPPER(SMS.[Level5Name]) as level5,       
						UPPER(SMS.[Level6Name]) as level6,       
						UPPER(SMS.[Level7Name]) as level7,       
						UPPER(SMS.[Level8Name]) as level8,       
						UPPER(SMS.[Level9Name]) as level9,       
						UPPER(SMS.[Level10Name])as level10,
						SMS.[Level1Id], 
						SMS.[Level2Id], 
						SMS.[Level3Id], 
						SMS.[Level4Id], 
						SMS.[Level5Id], 
						SMS.[Level6Id], 
						SMS.[Level7Id], 
						SMS.[Level8Id], 
						SMS.[Level9Id], 
						SMS.[Level10Id]
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
				INNER JOIN [dbo].[Currency] CR WITH(NOLOCK) ON CR.CurrencyId = SOBI.CurrencyId
				LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON SMS.[Level1Id] = MNSL.ID
				LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON SOBI.CustomerId = CF.CustomerId    
			    LEFT JOIN [dbo].[CreditTerms] CTM WITH(NOLOCK) ON CTM.CreditTermsId = CF.CreditTermsId  
				WHERE SOBI.MasterCompanyId=@MasterCompanyId	
				 AND SOBII.[IsDeleted] = 0 
				 AND SOBI.IsActive = 1 AND SOBI.IsDeleted = 0
				 AND ISNULL(SOBI.GrandTotal, 0) > 0
			
				UNION ALL

				SELECT DISTINCT CM.[CreditMemoHeaderId] [InvoicingId],				      
					   ROW_NUMBER() OVER (PARTITION BY CM.[CreditMemoNumber],I.ItemMasterId ORDER BY CM.CreditMemoHeaderId) AS [RowNum],
				       UPPER(CM.[CreditMemoNumber]) [InvoiceNum],
					   UPPER(CM.[Status]) [InvoiceStatus],	
					   CM.[CreatedDate] [InvoiceDate],
					   DATEADD(DAY, CTM.NetDays,CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
							CASE WHEN CAST(CM.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(CM.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
					   ELSE (CAST(CM.[CreatedDate] AS DATETIME)) END) as InvoiceDueDate,
					   CMD.[SOWONum] [WOSONum],									   
					   UPPER(C.[Name]) [CustomerName],
					   C.[CustomerCode],
					   C.[CustomerId],
					   CT.[CustomerTypeName] [CustomerType],						   				   
					   CMD.[Amount] [Amount],
					   CMD.[Amount] [RemainingAmount],
					   0 [AmountPaid],
					   I.[partnumber] [PN], 
					   I.[PartDescription] [PNDescription],
					   '' AS 'VersionNo',
					   '' [QuoteNumber],
					   CMD.[ReferenceNo] AS 'CustReference',					   
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
					   1 AS IsCreditMemo,
					   '' AS 'BaseCurrency',
					   UPPER(MNSL.Code) as level1,
						UPPER(MSD.[Level2Name]) as level2,       
						UPPER(MSD.[Level3Name]) as level3,       
						UPPER(MSD.[Level4Name]) as level4,       
						UPPER(MSD.[Level5Name]) as level5,       
						UPPER(MSD.[Level6Name]) as level6,       
						UPPER(MSD.[Level7Name]) as level7,       
						UPPER(MSD.[Level8Name]) as level8,       
						UPPER(MSD.[Level9Name]) as level9,       
						UPPER(MSD.[Level10Name])as level10,
						MSD.[Level1Id], 
						MSD.[Level2Id], 
						MSD.[Level3Id], 
						MSD.[Level4Id], 
						MSD.[Level5Id], 
						MSD.[Level6Id], 
						MSD.[Level7Id], 
						MSD.[Level8Id], 
						MSD.[Level9Id], 
						MSD.[Level10Id]
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
				 LEFT JOIN [dbo].ManagementStructureLevel MNSL WITH(NOLOCK) ON MSD.[Level1Id] = MNSL.ID
			WHERE CM.MasterCompanyId = @MasterCompanyid AND CM.IsActive = 1 AND CM.IsDeleted = 0

			),
			FinalResult AS (
				SELECT 
				0 as totalAmount,
				R.* 
				FROM Result R  
				WHERE (  
			  
				(@GlobalFilter <> '' AND (  
				  (InvoiceNum like '%' +@GlobalFilter+'%') OR  
				  (InvoiceStatus like '%' +@GlobalFilter+'%') OR  
				  (InvoiceDate like '%' +@GlobalFilter+'%') OR  
				  (WOSONum like '%' +@GlobalFilter+'%') OR    
				  (CustomerName like '%' +@GlobalFilter+'%') OR  
				  (CustomerType like '%' +@GlobalFilter+'%') OR 
				  (PN like '%' +@GlobalFilter+'%') OR  
				  (PNDescription like '%' +@GlobalFilter+'%') OR  
				  (VersionNo like '%' +@GlobalFilter+'%') OR 
				  (QuoteNumber like '%' +@GlobalFilter+'%') OR 
				  (CustReference like '%' +@GlobalFilter+'%') OR  
				  (SerialNumber like '%' +@GlobalFilter+'%') OR
				  (LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
				  (StockType like '%' +@GlobalFilter+'%')))  
				 OR     
				 (@GlobalFilter='' AND (IsNull(@InvoiceNum,'') ='' OR InvoiceNum like '%' + @InvoiceNum+'%') AND  
				  (IsNull(@InvoiceDate,'') ='' OR Cast(InvoiceDate as date)=Cast(@InvoiceDate as date)) and 
				  (IsNull(@WOSONum,'') ='' OR WOSONum like '%' + @WOSONum+'%') AND  
				  (IsNull(@CustomerName,'') ='' OR CustomerName like '%' + @CustomerName+'%') AND  
				  (IsNull(CAST( @Amount as varchar),'') ='' OR Cast(Amount as varchar) like '%' + CAST(@Amount as varchar)+'%') AND  
				  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
				  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
				  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND   
				  (IsNull(@CustReference,'') ='' OR CustReference like '%' + @CustReference+'%') AND  
				  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
				  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') and
				 (@FromDate IS NULL OR CAST(InvoiceDate AS DATE) >= CAST(@FromDate AS DATE)) AND
				 (@ToDate IS NULL OR CAST(InvoiceDate AS DATE) <= CAST(@ToDate AS DATE)) AND
				  (1=1)
				  ))
			), 
			CustomerWiseResult AS
				(
					SELECT
						CustomerId,
						CustomerName,
						CustomerCode,
						SUM(Amount) AS amount,
						CASE 
							WHEN COUNT(DISTINCT InvoiceNum) > 1 
								THEN 'Multiple'
							ELSE MAX(InvoiceNum)
						END AS InvoiceNum,

						CASE 
							WHEN COUNT(DISTINCT InvoiceStatus) > 1 
								THEN 'Multiple'
							ELSE MAX(InvoiceStatus)
						END AS InvoiceStatus,

						MAX(InvoiceDate) InvoiceDate,
					
						CASE 
							WHEN COUNT(DISTINCT WOSONum) > 1 
								THEN 'Multiple'
							ELSE MAX(WOSONum)
						END AS WOSONum,
						CASE 
							WHEN COUNT(DISTINCT CustomerType) > 1 
								THEN 'Multiple'
							ELSE MAX(CustomerType)
						END AS CustomerType,

						CASE 
							WHEN COUNT(DISTINCT BaseCurrency) > 1 
								THEN 'Multiple'
							ELSE MAX(BaseCurrency)
						END AS BaseCurrency,

						CASE 
							WHEN COUNT(DISTINCT PN) > 1 
								THEN 'Multiple'
							ELSE MAX(PN)
						END AS PN,

						CASE 
							WHEN COUNT(DISTINCT PNDescription) > 1 
								THEN 'Multiple'
							ELSE MAX(PNDescription)
						END AS PNDescription,

						CASE 
							WHEN COUNT(DISTINCT VersionNo) > 1 
								THEN 'Multiple'
							ELSE MAX(VersionNo)
						END AS VersionNo,

						CASE 
							WHEN COUNT(DISTINCT QuoteNumber) > 1 
								THEN 'Multiple'
							ELSE MAX(QuoteNumber)
						END AS QuoteNumber,

						CASE 
							WHEN COUNT(DISTINCT CustReference) > 1 
								THEN 'Multiple'
							ELSE MAX(CustReference)
						END AS CustReference,

						CASE 
							WHEN COUNT(DISTINCT SerialNumber) > 1 
								THEN 'Multiple'
							ELSE MAX(SerialNumber)
						END AS SerialNumber,

						CASE 
							WHEN COUNT(DISTINCT StockType) > 1 
								THEN 'Multiple'
							ELSE MAX(StockType)
						END AS StockType,

						CASE 
							WHEN COUNT(DISTINCT LastMSLevel) > 1 
								THEN 'Multiple'
							ELSE MAX(LastMSLevel)
						END AS LastMSLevel,
						MAX(level1) AS level1,
						MAX(level2) AS level2,
						MAX(level3) AS level3,
						MAX(level4) AS level4,
						MAX(level5) AS level5,
						MAX(level6) AS level6,
						MAX(level7) AS level7,
						MAX(level8) AS level8,
						MAX(level9) AS level9,
						MAX(level10) AS level10
					FROM FinalResult
					WHERE CustomerId IS NOT NULL
					GROUP BY
						CustomerId,
						CustomerName,
						CustomerCode
				),

			   ResultCount AS (
					SELECT COUNT(CustomerId) AS NumberOfItems FROM CustomerWiseResult
			   )
				  SELECT * FROM CustomerWiseResult, ResultCount  
				   ORDER BY       
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='WOSONum')  THEN WOSONum END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerName')  THEN CustomerName END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustomerType')  THEN CustomerType END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='Amount')  THEN Amount END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PN')  THEN PN END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='PNDescription')  THEN PNDescription END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='VersionNo')  THEN VersionNo END ASC, 
				   CASE WHEN (@SortOrder=1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='CustReference')  THEN CustReference END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='SerialNumber')  THEN SerialNumber END ASC,  
				   CASE WHEN (@SortOrder=1 and @SortColumn='StockType')  THEN StockType END ASC,
				   CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,
						
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='invoiceStatus')  THEN InvoiceStatus END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='WOSONum')  THEN WOSONum END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerName')  THEN CustomerName END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustomerType')  THEN CustomerType END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='Amount')  THEN Amount END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PN')  THEN PN END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='PNDescription')  THEN PNDescription END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='VersionNo')  THEN VersionNo END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='QuoteNumber')  THEN QuoteNumber END DESC, 
				   CASE WHEN (@SortOrder=-1 and @SortColumn='CustReference')  THEN CustReference END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNumber')  THEN SerialNumber END DESC,  
				   CASE WHEN (@SortOrder=-1 and @SortColumn='StockType')  THEN StockType END DESC,
				   CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC
  
				   OFFSET @RecordFrom ROWS   
				   FETCH NEXT @PageSize ROWS ONLY	
			END
  END TRY
  BEGIN CATCH
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF OBJECT_ID(N'tempdb..#TEMPInvoiceRecordsDetailsView') IS NOT NULL
    BEGIN
      DROP TABLE #TEMPInvoiceRecordsDetailsView
    END

    DECLARE @ErrorLogID int,
        @DatabaseName varchar(100) = DB_NAME(),
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        @AdhocComments varchar(150) = '[usprpt_CustomerInvoiceReportList]',
        @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END