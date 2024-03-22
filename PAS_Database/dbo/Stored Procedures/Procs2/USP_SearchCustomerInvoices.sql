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

exec dbo.USP_SearchCustomerInvoices 
@PageSize=10,@PageNumber=1,@SortColumn=NULL,@SortOrder=-1,@StatusID=0,@GlobalFilter=N'',@InvoiceNo=NULL,@InvoiceStatus=NULL,@InvoiceDate=NULL,
@OrderNumber=NULL,@CustomerName=NULL,@CustomerType=NULL,@InvoiceAmt=NULL,@PN=NULL,@PNDescription=NULL,@VersionNo=NULL,@QuoteNumber=NULL,
@CustomerReference=NULL,@MasterCompanyId=1,@SerialNumber=NULL,@StockType=NULL,@ViewType=N'invoice',@EmployeeId=2,@RemainingAmount=NULL,@LastMSLevel=NULL,@Status=N''
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SearchCustomerInvoices]
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
@Status varchar(50)=null
AS
BEGIN
	  DECLARE @RecordFrom INT; 
	  DECLARE @ModuleID VARCHAR(500) ='12'
	  DECLARE @SOModuleID VARCHAR(500) ='17'
	  DECLARE @ExchSOModuleID VARCHAR(500) ='19'
	  DECLARE @IsActive BIT = 1  
	  DECLARE @Count INT;  
	  SET @RecordFrom = (@PageNumber - 1) * @PageSize;

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
				   WOBI.InvoiceDate [InvoiceDate],
				   WO.WorkOrderNum [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   WOBI.GrandTotal [InvoiceAmt],
				   ISNULL(WOBI.RemainingAmount,0) RemainingAmount,
				   ISNULL(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,
				   WQ.QuoteNumber,
				   IsWorkOrder=1,
				   IsExchange=0,
				   WOBI.WorkOrderId AS [ReferenceId],
				   C.CustomerId,--WOWF.WorkFlowWorkOrderId, --0 as WorkFlowWorkOrderId,
				   CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate,
				   ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				   WOPN.ManagementStructureId
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOPN.ID and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
			Where WOBI.MasterCompanyId=@MasterCompanyId AND WOBI.IsVersionIncrease=0
			AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0
			),				
			LastMSLevelCTE AS(  
			Select PC.BillingInvoicingId,(Case When Count(WOPN.ManagementStructureId) > 1 Then 'Multiple' ELse max(M.LastMSLevel) End)  as 'LastMSLevel'  
			,a.AllMSlevels
			from dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
			LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
			LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =PC.WorkOrderId and WOPN.ID=WOBII.WorkOrderPartId
			LEFT JOIN dbo.WorkorderManagementStructureDetails M WITH (NOLOCK) ON M.ReferenceID = WOPN.ID AND M.ModuleID = @ModuleID
			Outer Apply(  
				SELECT   
				STUFF((SELECT CASE WHEN LEN(MS.AllMSlevels) >0 then ',' ELSE '' END + MS.AllMSlevels  
				FROM  dbo.WorkorderManagementStructureDetails MS WITH (NOLOCK)
			INNER JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) on MS.ReferenceID=WOPN.ID AND WOPN.WorkOrderId =PC.WorkOrderId
			INNER JOIN  dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) on WOBII.WorkOrderPartId=WOPN.ID AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				where MS.ModuleID=@ModuleID and WOBII.BillingInvoicingId=PC.BillingInvoicingId
				FOR XML PATH('')), 1, 1, '') AllMSlevels 				  
			) A  
			WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND M.ModuleID = @ModuleID AND ISNULL(PC.[IsInvoicePosted], 0) != 1
			Group By PC.BillingInvoicingId
			,A.AllMSlevels				 
			),
			VersionCTE AS(  
			Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse A.VersionNo End)  as 'VersionNo',  
			A.VersionNo [VersionNoType] 
			FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
			LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
			LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =PC.WorkOrderId and WOPN.ID=WOBII.WorkOrderPartId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON PC.WorkOrderId = WO.WorkOrderId
			LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
			Outer Apply(  
				SELECT   
				STUFF((SELECT CASE WHEN LEN(WQ.VersionNo) >0 then ',' ELSE '' END + WQ.VersionNo  
					FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					Left Join dbo.WorkOrderPartNumber I WITH (NOLOCK) On I.ID=S.WorkOrderPartId 
					LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON PC.WorkOrderId = WO.WorkOrderId
					LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
					Where S.BillingInvoicingId = PC.BillingInvoicingId  
					AND S.IsActive = 1 AND S.IsDeleted = 0  
					AND ISNULL(S.[IsInvoicePosted], 0) != 1
					FOR XML PATH('')), 1, 1, '') VersionNo   
			) A  
			WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
			Group By PC.BillingInvoicingId, A.VersionNo  
			),
			CRefCTE AS(  
			Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse A.CustomerReference End)  as 'CustomerReference',  
			A.CustomerReference [CustomerReferenceType] 
			FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
			LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
			LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =PC.WorkOrderId and WOPN.ID=WOBII.WorkOrderPartId
			Outer Apply(  
				SELECT   
				STUFF((SELECT CASE WHEN LEN(I.CustomerReference) >0 then ',' ELSE '' END + I.CustomerReference  
					FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					Left Join dbo.WorkOrderPartNumber I WITH (NOLOCK) On I.ID=S.WorkOrderPartId  
					Where S.BillingInvoicingId = PC.BillingInvoicingId  
					AND S.IsActive = 1 AND S.IsDeleted = 0  
					AND ISNULL(S.[IsInvoicePosted], 0) != 1
					FOR XML PATH('')), 1, 1, '') CustomerReference  
			) A  
			WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
			Group By PC.BillingInvoicingId, A.CustomerReference  
			),
			SRNoCTE AS(  
			Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse A.SerialNumber End)  as 'SerialNumber',  
			A.SerialNumber [SerialNumberType] FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
			LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
			LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =PC.WorkOrderId and WOPN.ID=WOBII.WorkOrderPartId
			LEFT JOIN dbo.Stockline STL WITH (NOLOCK) ON STL.StockLineId=WOPN.StockLineId
			Outer Apply(  
				SELECT   
				STUFF((SELECT CASE WHEN LEN(ST.SerialNumber) >0 then ',' ELSE '' END + ST.SerialNumber 
					FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					Left Join dbo.WorkOrderPartNumber I WITH (NOLOCK) On I.ID=S.WorkOrderPartId 
					LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=I.StockLineId
					Where S.BillingInvoicingId = PC.BillingInvoicingId  
					AND S.IsActive = 1 AND S.IsDeleted = 0  
					AND ISNULL(S.[IsInvoicePosted], 0) != 1
					FOR XML PATH('')), 1, 1, '') SerialNumber  
			) A  
			WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
			Group By PC.BillingInvoicingId, A.SerialNumber  
			),
			PartCTE AS(  
				Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PN',  
				A.PartNumber [PartNumberType] FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.partnumber) >0 then ',' ELSE '' END + I.partnumber  
					 FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.BillingInvoicingId = PC.BillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 AND ISNULL(S.[IsInvoicePosted], 0) != 1
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				Group By PC.BillingInvoicingId, A.PartNumber  
				),
				PartDescCTE AS(  
				Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PNDescription',  
				A.PartDescription [PartDescriptionType] FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.PartDescription) >0 then ',' ELSE '' END + I.PartDescription  
					 FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.BillingInvoicingId = PC.BillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 AND ISNULL(S.[IsInvoicePosted], 0) != 1
					 FOR XML PATH('')), 1, 1, '') PartDescription  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				Group By PC.BillingInvoicingId, A.PartDescription  
				),
				StockCTE AS(  
				Select PC.BillingInvoicingId,(Case When Count(WOBII.BillingInvoicingId) > 1 Then 'Multiple' ELse 
				A.StockType End)  as 'StockType',  
				A.StockType [StocktypeType] FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =PC.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT ',' + CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					 ELSE 'OEM' END   
					 FROM dbo.WorkOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ItemMaster IM WITH (NOLOCK) On S.ItemMasterId=IM.ItemMasterId  
					 Where S.BillingInvoicingId = PC.BillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 AND ISNULL(S.[IsInvoicePosted], 0) != 1
					 FOR XML PATH('')), 1, 1, '') StockType  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				Group By PC.BillingInvoicingId, A.StockType  
				),
				WorkFlowData AS(  
				Select PC.BillingInvoicingId,WOFN.WorkFlowWorkOrderId, PC.WorkOrderId
				FROM dbo.WorkOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.WorkOrderWorkFlow WOFN WITH (NOLOCK) ON WOFN.WorkFlowWorkOrderId = PC.WorkFlowWorkOrderId
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease = 0 AND ISNULL(PC.[IsInvoicePosted], 0) != 1
				Group By PC.WorkOrderId,PC.BillingInvoicingId,WOFN.WorkFlowWorkOrderId
				),
				Results AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PT.PN [PN],PD.PNDescription [PNDescription],
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				VC.VersionNo,VC.VersionNoType,M.QuoteNumber,
				CR.CustomerReference,CR.CustomerReferenceType,SRC.SerialNumber,SRC.SerialNumberType,M.IsWorkOrder,M.IsExchange,
				LMC.LastMSLevel,LMC.AllMSlevels, M.ReferenceId,M.CustomerId,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM Result M   
					Left Join PartCTE PT On M.InvoicingId = PT.BillingInvoicingId  
					Left Join PartDescCTE PD on PD.BillingInvoicingId = M.InvoicingId
					LEFT JOIN StockCTE SC ON SC.BillingInvoicingId=M.InvoicingId
					LEFT JOIN CRefCTE CR ON CR.BillingInvoicingId=M.InvoicingId
					LEFT JOIN SRNoCTE SRC on SRC.BillingInvoicingId=M.InvoicingId
					LEFT JOIN VersionCTE VC on VC.BillingInvoicingId=M.InvoicingId
					LEFT JOIN LastMSLevelCTE LMC  on LMC.BillingInvoicingId=M.InvoicingId
					LEFT JOIN WorkFlowData WOFD  on WOFD.BillingInvoicingId=M.InvoicingId
					group by 
					M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,PN,PD.PNDescription,
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				VC.VersionNo,VC.VersionNoType,M.QuoteNumber,LMC.LastMSLevel,LMC.AllMSlevels	,
				CR.CustomerReference,CR.CustomerReferenceType,SRC.SerialNumber,SRC.SerialNumberType,M.IsWorkOrder, M.ReferenceId,M.CustomerId,M.IsExchange,WOFD.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId)
			,SOResult AS(
				SELECT DISTINCT 
				       SOBI.SOBillingInvoicingId [InvoicingId],
				       SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   SOBI.InvoiceDate [InvoiceDate],
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
					   SOBI.SalesOrderId AS [ReferenceId],
					   C.CustomerId,0 as WorkFlowWorkOrderId,
					   CASE WHEN CRM.RMAHeaderId > 1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsProforma, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
			FROM dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				--LEFT JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId AND ISNULL(SOBII.[IsBilling], 0) != 1
				--LEFT JOIN dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				--LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.SOBillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
			Where SOBI.MasterCompanyId=@MasterCompanyId AND SOBI.IsVersionIncrease=0 AND ISNULL(SOBI.[IsBilling], 0) != 1 AND ISNULL(SOBI.RemainingAmount,0) > 0
			),
			SVersionCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.VersionNo End)  as 'VersionNo',  
				A.VersionNo [VersionNoType] 
				FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				--LEFT JOIN dbo.SalesOrderPart WOPN WITH (NOLOCK) ON WOPN.SalesOrderId =PC.SalesOrderId and WOPN.SalesOrderPartId=WOBII.SalesOrderPartId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(SQ.VersionNumber) >0 then ',' ELSE '' END + SQ.VersionNumber 
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.SalesOrderPart I WITH (NOLOCK) On I.SalesOrderPartId=S.SalesOrderPartId 
					 LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON I.SalesOrderId = SO.SalesOrderId
					 LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId AND ISNULL(S.[IsBilling], 0) != 1 
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') VersionNo  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId AND PC.IsVersionIncrease=0 AND ISNULL(PC.[IsBilling], 0) != 1 
				Group By PC.SOBillingInvoicingId, A.VersionNo  
				),
			SCRefCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.CustomerReference End)  as 'CustomerReference',  
				A.CustomerReference [CustomerReferenceType] 
				FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				LEFT JOIN dbo.SalesOrderPart WOPN WITH (NOLOCK) ON WOPN.SalesOrderId =PC.SalesOrderId and WOPN.SalesOrderPartId=WOBII.SalesOrderPartId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.CustomerReference) >0 then ',' ELSE '' END + I.CustomerReference  
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.SalesOrderPart I WITH (NOLOCK) On I.SalesOrderPartId=S.SalesOrderPartId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') CustomerReference  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId AND ISNULL(PC.[IsBilling], 0) != 1
				Group By PC.SOBillingInvoicingId, A.CustomerReference  
				),
				SSRNoCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.SerialNumber End)  as 'SerialNumber',  
				ISNULL(A.SerialNumber,'') [SerialNumberType] 
				FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				--LEFT JOIN dbo.SalesOrderPart WOPN WITH (NOLOCK) ON WOPN.SalesOrderId =PC.SalesOrderId and WOPN.SalesOrderPartId=WOBII.SalesOrderPartId
				--LEFT JOIN dbo.Stockline STL WITH (NOLOCK) ON STL.StockLineId=WOPN.StockLineId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(ST.SerialNumber) >0 then ',' ELSE '' END + ST.SerialNumber 
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.SalesOrderPart I WITH (NOLOCK) On I.SalesOrderPartId=S.SalesOrderPartId 
					 LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=I.StockLineId
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  AND ISNULL(PC.[IsBilling], 0) != 1
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') SerialNumber  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.SerialNumber  
				),
			SOPartCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PN',  
				A.PartNumber [PartNumberType] FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.partnumber) >0 then ',' ELSE '' END + I.partnumber  
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId AND ISNULL(PC.[IsBilling], 0) != 1  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.PartNumber  
				),
				SOPartDescCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PNDescription',  
				A.PartDescription [PartDescriptionType] FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.PartDescription) >0 then ',' ELSE '' END + I.PartDescription  
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  AND ISNULL(PC.[IsBilling], 0) != 1
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartDescription  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.PartDescription  
				),
				SOStockCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse 
				A.StockType End)  as 'StockType',  
				A.StockType [StocktypeType] FROM dbo.SalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId AND ISNULL(WOBII.[IsBilling], 0) != 1
				Outer Apply(  
				 SELECT   
					STUFF((SELECT ',' + CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					 ELSE 'OEM' END  
					 FROM dbo.SalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ItemMaster IM WITH (NOLOCK) On S.ItemMasterId=IM.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  AND ISNULL(PC.[IsBilling], 0) != 1
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') StockType  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.StockType  
				),
				SOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount, M.AmountPaid, PT.PN [PN],PD.PNDescription [PNDescription],
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				--M.VersionNo,
				SVC.VersionNo,SVC.VersionNoType,
				M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				CR.CustomerReference,ISNULL(SRC.SerialNumber,'') [SerialNumber],M.IsWorkOrder,CR.CustomerReferenceType,SRC.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM SOResult M   
					Left Join SOPartCTE PT On M.InvoicingId = PT.SOBillingInvoicingId  
					Left Join SOPartDescCTE PD on PD.SOBillingInvoicingId = M.InvoicingId
					LEFT JOIN SOStockCTE SC ON SC.SOBillingInvoicingId=M.InvoicingId
					LEFT JOIN SCRefCTE CR ON CR.SOBillingInvoicingId=M.InvoicingId
					LEFT JOIN SSRNoCTE SRC on SRC.SOBillingInvoicingId=M.InvoicingId
					LEFT JOIN SVersionCTE SVC on SVC.SOBillingInvoicingId=M.InvoicingId
					group by 
					M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,PD.PNDescription,
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				SVC.VersionNo,SVC.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				CR.CustomerReference,ISNULL(SRC.SerialNumber,''),M.IsWorkOrder,CR.CustomerReferenceType,SRC.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
					),


				ExchSOResult AS(
			SELECT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   SOBI.InvoiceDate [InvoiceDate],
				   SO.ExchangeSalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt],
				   ISNULL(SOBI.GrandTotal,0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,
				--SQ.ExchangeSalesOrderQuoteNumber [QuoteNumber],
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
			FROM dbo.ExchangeSalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId =SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart SOPN WITH (NOLOCK) ON SOPN.ExchangeSalesOrderId =SOBI.ExchangeSalesOrderId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON SOBI.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
				--LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.ExchangeManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.ExchangeSalesOrderId AND SMS.ModuleID = @ExchSOModuleID 
			Where SOBI.MasterCompanyId=@MasterCompanyId	AND SOBII.IsDeleted=0 AND ISNULL(SOBI.GrandTotal,0) > 0	
			),
			ExchSVersionCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.VersionNo End)  as 'VersionNo',  
				A.VersionNo [VersionNoType] 
				FROM dbo.ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart WOPN WITH (NOLOCK) ON WOPN.ExchangeSalesOrderId =PC.ExchangeSalesOrderId and WOPN.ExchangeSalesOrderPartId=WOBII.ExchangeSalesOrderPartId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(SO.VersionNumber) >0 then ',' ELSE '' END + SO.VersionNumber 
					 FROM dbo.ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.ExchangeSalesOrderPart I WITH (NOLOCK) On I.ExchangeSalesOrderPartId=S.ExchangeSalesOrderPartId 
					 LEFT JOIN dbo.ExchangeSalesOrder SO WITH (NOLOCK) ON I.ExchangeSalesOrderId = SO.ExchangeSalesOrderId
					 --LEFT JOIN SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId=SO.SalesOrderQuoteId
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') VersionNo  
				) A  
				WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.VersionNo  
				),
			--ExchSCRefCTE AS(  
			--	Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.CustomerReference End)  as 'CustomerReference',  
			--	A.CustomerReference [CustomerReferenceType] 
			--	from ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
			--	LEFT JOIN ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
			--	LEFT JOIN ExchangeSalesOrderPart WOPN WITH (NOLOCK) ON WOPN.ExchangeSalesOrderId =PC.ExchangeSalesOrderId and WOPN.ExchangeSalesOrderPartId=WOBII.ExchangeSalesOrderPartId
			--	Outer Apply(  
			--	 SELECT   
			--		STUFF((SELECT CASE WHEN LEN(I.CustomerReference) >0 then ',' ELSE '' END + I.CustomerReference  
			--		 FROM ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
			--		 Left Join ExchangeSalesOrderPart I WITH (NOLOCK) On I.ExchangeSalesOrderPartId=S.ExchangeSalesOrderPartId  
			--		 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
			--		 AND S.IsActive = 1 AND S.IsDeleted = 0  
			--		 FOR XML PATH('')), 1, 1, '') CustomerReference  
			--	) A  
			--	WHERE PC.MasterCompanyId=@MasterCompanyId
			--	Group By PC.SOBillingInvoicingId, A.CustomerReference  
			--	),
				ExchSSRNoCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.SerialNumber End)  as 'SerialNumber',  
				ISNULL(A.SerialNumber,'') [SerialNumberType] 
				FROM dbo.ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
				LEFT JOIN dbo.ExchangeSalesOrderPart WOPN WITH (NOLOCK) ON WOPN.ExchangeSalesOrderId =PC.ExchangeSalesOrderId and WOPN.ExchangeSalesOrderPartId=WOBII.ExchangeSalesOrderPartId
				LEFT JOIN dbo.Stockline STL WITH (NOLOCK) ON STL.StockLineId=WOPN.StockLineId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(ST.SerialNumber) >0 then ',' ELSE '' END + ST.SerialNumber 
					 FROM dbo.ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ExchangeSalesOrderPart I WITH (NOLOCK) On I.ExchangeSalesOrderPartId=S.ExchangeSalesOrderPartId 
					 LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') SerialNumber  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.SerialNumber  
				),
			ExchSOPartCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PN',  
				A.PartNumber [PartNumberType] FROM dbo.ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.partnumber) >0 then ',' ELSE '' END + I.partnumber  
					 FROM dbo.ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartNumber  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.PartNumber  
				),
				ExchSOPartDescCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PNDescription',  
				A.PartDescription [PartDescriptionType] FROM dbo.ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT CASE WHEN LEN(I.PartDescription) >0 then ',' ELSE '' END + I.PartDescription  
					 FROM dbo.ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 Left Join dbo.ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') PartDescription  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.PartDescription  
				),
				ExchSOStockCTE AS(  
				Select PC.SOBillingInvoicingId,(Case When Count(WOBII.SOBillingInvoicingId) > 1 Then 'Multiple' ELse 
				A.StockType End)  as 'StockType',  
				A.StockType [StocktypeType] FROM dbo.ExchangeSalesOrderBillingInvoicing PC WITH (NOLOCK) 
				LEFT JOIN dbo.ExchangeSalesOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.SOBillingInvoicingId =PC.SOBillingInvoicingId
				Outer Apply(  
				 SELECT   
					STUFF((SELECT ',' + CASE WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
					 WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
					 WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
					 ELSE 'OEM' END  
					 FROM dbo.ExchangeSalesOrderBillingInvoicingItem S WITH (NOLOCK)  
					 LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) On S.ItemMasterId=IM.ItemMasterId  
					 Where S.SOBillingInvoicingId = PC.SOBillingInvoicingId  
					 AND S.IsActive = 1 AND S.IsDeleted = 0  
					 FOR XML PATH('')), 1, 1, '') StockType  
				) A  
				 WHERE PC.MasterCompanyId=@MasterCompanyId
				Group By PC.SOBillingInvoicingId, A.StockType  
				),
				ExchSOResults AS( SELECT M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid,PT.PN as [PN],PD.PNDescription [PNDescription],
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				--M.VersionNo,
				SVC.VersionNo,SVC.VersionNoType,
				--M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				'' as QuoteNumber,
				M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				--CR.CustomerReference,ISNULL(SRC.SerialNumber,'') [SerialNumber],M.IsWorkOrder,CR.CustomerReferenceType,SRC.SerialNumberType,M.CustomerId
				M.CustomerReference,'' as CustomerReferenceType,
				ISNULL(SRC.SerialNumber,'') [SerialNumber],M.IsWorkOrder,SRC.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				FROM ExchSOResult M   
					Left Join ExchSOPartCTE PT On M.InvoicingId = PT.SOBillingInvoicingId  
					Left Join ExchSOPartDescCTE PD on PD.SOBillingInvoicingId = M.InvoicingId
					LEFT JOIN ExchSOStockCTE SC ON SC.SOBillingInvoicingId=M.InvoicingId
					--LEFT JOIN ExchSCRefCTE CR ON CR.SOBillingInvoicingId=M.InvoicingId
					LEFT JOIN ExchSSRNoCTE SRC on SRC.SOBillingInvoicingId=M.InvoicingId
					LEFT JOIN ExchSVersionCTE SVC on SVC.SOBillingInvoicingId=M.InvoicingId
					group by 
					M.InvoicingId,M.InvoiceNo,M.InvoiceStatus,M.InvoiceDate,M.OrderNumber,
				M.CustomerName,M.CustomerType,M.InvoiceAmt,M.RemainingAmount,M.AmountPaid, PN,PD.PNDescription,
				PT.PartNumberType,PD.PartDescriptionType,SC.StockType,SC.StocktypeType,
				SVC.VersionNo,SVC.VersionNoType,M.QuoteNumber,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				--SVC.VersionNo,SVC.VersionNoType,M.LastMSLevel,M.AllMSlevels, M.ReferenceId, 
				--CR.CustomerReference,ISNULL(SRC.SerialNumber,''),M.IsWorkOrder,CR.CustomerReferenceType,SRC.SerialNumberType,M.CustomerId
				M.CustomerReference,ISNULL(SRC.SerialNumber,''),M.IsWorkOrder,M.CustomerReferenceType,SRC.SerialNumberType,M.CustomerId,M.IsExchange,M.WorkFlowWorkOrderId,M.isRMACreate,M.IsPerformaInvoice,M.ManagementStructureId
				--ISNULL(SRC.SerialNumber,''),M.IsWorkOrder,SRC.SerialNumberType,M.CustomerId
					)
			   , FinalResult AS(
					SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt, RemainingAmount, AmountPaid ,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				FROM Results
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount, AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber ,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				FROM SOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
					UNION ALL 
				SELECT InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid, [PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				--VersionNo,VersionNoType,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				--SerialNumber,IsWorkOrder,SerialNumberType, ReferenceId,CustomerId
				FROM ExchSOResults
				GROUP BY 
				InvoicingId,InvoiceNo,InvoiceStatus,invoiceDate,OrderNumber,
				CustomerName,CustomerType,InvoiceAmt,RemainingAmount,AmountPaid,[PN], [PNDescription],
				PartNumberType,PartDescriptionType,StockType,StocktypeType,
				VersionNo,VersionNoType,QuoteNumber,LastMSLevel,AllMSlevels,
				--VersionNo,VersionNoType,LastMSLevel,AllMSlevels,
				CustomerReference,SerialNumber,IsWorkOrder,CustomerReferenceType,SerialNumberType, ReferenceId,CustomerId,IsExchange,WorkFlowWorkOrderId,isRMACreate,IsPerformaInvoice,ManagementStructureId
				--SerialNumber,IsWorkOrder,SerialNumberType, ReferenceId,CustomerId
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
      (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
      (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
      (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND 
	  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND
      (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
      (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND  
      (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')  AND
	  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') AND
	  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%') 
      ))
				   SELECT @Count = COUNT(InvoicingId) from #TempResult     
  
				   SELECT *, @Count As NumberOfItems FROM #TempResult  
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
				SELECT WOBI.BillingInvoicingId [InvoicingId],
				WOBI.InvoiceNo [InvoiceNo],
				WOBI.InvoiceStatus [InvoiceStatus],
				WOBI.InvoiceDate [InvoiceDate],
				WO.WorkOrderNum [OrderNumber],
				C.Name [CustomerName],
				CT.CustomerTypeName [CustomerType],
				WOBI.GrandTotal [InvoiceAmt], 
				ISNULL(WOBI.RemainingAmount, 0)  RemainingAmount,
				ISNULL(ISNULL(WOBI.GrandTotal,0) - ISNULL(WOBI.RemainingAmount,0),0) AmountPaid,				
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
					 WOBI.WorkOrderId AS [ReferenceId],WOWF.WorkFlowWorkOrderId,
			    CASE WHEN CRM.RMAHeaderId >1 then 1 else  0 end isRMACreate
					 ,ISNULL(WOBI.IsPerformaInvoice, 0) AS IsPerformaInvoice,
				MSD.EntityMSID AS ManagementStructureId
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				LEFT JOIN dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId AND ISNULL(WOBII.[IsInvoicePosted], 0) != 1
				LEFT JOIN dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOPN.ID =WOWF.WorkOrderPartNoId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON WOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuote WQ WITH (NOLOCK) ON WQ.WorkOrderId = WO.WorkOrderId
				LEFT JOIN dbo.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WQD.WOPartNoId = WOBII.WorkOrderPartId and WQD.WorkOrderQuoteId=WQ.WorkOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=WOBI.BillingInvoicingId and CRM.isWorkOrder=1
				LEFT JOIN dbo.WorkorderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = WOPN.ID AND MSD.ModuleID = @ModuleID
			Where WOBI.MasterCompanyId=@MasterCompanyId AND WOBI.IsVersionIncrease=0
			AND ISNULL(WOBI.[IsInvoicePosted], 0) != 1 AND ISNULL(WOBI.RemainingAmount,0) > 0

			UNION ALL

			SELECT SOBI.SOBillingInvoicingId [InvoicingId],
			       SOBI.InvoiceNo [InvoiceNo],
				   SOBI.InvoiceStatus [InvoiceStatus],
				   SOBI.InvoiceDate [InvoiceDate],
				   SO.SalesOrderNumber [OrderNumber],
				   C.Name [CustomerName],
				   CT.CustomerTypeName [CustomerType],
				   SOBI.GrandTotal [InvoiceAmt], 
				   ISNULL(SOBI.RemainingAmount, 0) RemainingAmount,
				   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,						
				   IM.partnumber [PN], 
				   IM.PartDescription [PNDescription],
				   SQ.VersionNumber [VersionNo],
				   SQ.SalesOrderQuoteNumber [QuoteNumber],
				   SOPN.CustomerReference [CustomerReference],
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
					   SOBI.SalesOrderId AS [ReferenceId],
					   0 as WorkFlowWorkOrderId,
					   CASE WHEN Max(CRM.RMAHeaderId) >1 then 1 else  0 end isRMACreate
					   ,ISNULL(SOBI.IsProforma, 0) AS IsPerformaInvoice,
					   SMS.EntityMSID AS ManagementStructureId
			FROM dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK)
				LEFT JOIN dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
				LEFT JOIN dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId
				LEFT JOIN dbo.Customer C WITH (NOLOCK) ON SOBI.CustomerId = C.CustomerId
				LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SOBI.SalesOrderId = SO.SalesOrderId
				LEFT JOIN dbo.SalesOrderQuote SQ WITH (NOLOCK) ON SQ.SalesOrderQuoteId = SO.SalesOrderQuoteId
				LEFT JOIN dbo.CustomerType CT WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
				LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON SOBII.ItemMasterId=IM.ItemMasterId
				LEFT JOIN dbo.Stockline ST WITH (NOLOCK) ON ST.StockLineId=SOPN.StockLineId
				LEFT JOIN dbo.CustomerRMAHeader CRM WITH (NOLOCK) ON CRM.InvoiceId=SOBI.SOBillingInvoicingId and CRM.isWorkOrder=0
				LEFT JOIN dbo.SalesOrderManagementStructureDetails SMS WITH (NOLOCK) ON SMS.ReferenceID = SO.SalesOrderId AND SMS.ModuleID = @SOModuleID 
			WHERE SOBI.MasterCompanyId=@MasterCompanyId AND SOBII.IsVersionIncrease=0 AND ISNULL(SOBI.[IsBilling], 0) != 1 AND ISNULL(SOBI.RemainingAmount,0) > 0
				GROUP BY SOBI.SOBillingInvoicingId,SOBI.InvoiceNo,
					SOBI.InvoiceStatus ,SOBI.InvoiceDate,SO.SalesOrderNumber,
					C.Name ,CT.CustomerTypeName , SOBI.RemainingAmount,
					SOBI.GrandTotal ,IM.partnumber , IM.PartDescription ,
					SQ.VersionNumber,SQ.SalesOrderQuoteNumber ,SOPN.CustomerReference ,ST.SerialNumber,ST.stocklineid ,
					IM.IsPma,IM.IsDER,SMS.LastMSLevel,SMS.AllMSlevels, SOBI.SalesOrderId, SOBI.IsProforma,SMS.EntityMSID

			UNION ALL

				SELECT SOBI.SOBillingInvoicingId [InvoicingId],
					   SOBI.InvoiceNo [InvoiceNo],
					   SOBI.InvoiceStatus [InvoiceStatus],
					   SOBI.InvoiceDate [InvoiceDate],
					   SO.ExchangeSalesOrderNumber [OrderNumber],
					   C.Name [CustomerName],
					   CT.CustomerTypeName [CustomerType],
					   SOBI.GrandTotal [InvoiceAmt],
					   ISNULL(SOBI.GrandTotal,0) RemainingAmount,
					   ISNULL(ISNULL(SOBI.GrandTotal,0) - ISNULL(SOBI.RemainingAmount,0),0) AmountPaid,		
					   IM.partnumber [PN], 
					   IM.PartDescription [PNDescription],
					   '' [VersionNo],
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
					   SMS.EntityMSID AS ManagementStructureId
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
			
			), ResultCount AS(SELECT COUNT(InvoicingId) AS totalItems FROM Result)  
			   SELECT * INTO #TempResults from  Result
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
				  (IsNull(@PN,'') ='' OR PN like '%' + @PN+'%') AND  
				  (IsNull(@PNDescription,'') ='' OR PNDescription like '%' + @PNDescription+'%') AND  
				  (IsNull(@VersionNo,'') ='' OR VersionNo like '%' + @VersionNo+'%') AND   
				  (IsNull(@QuoteNumber,'') ='' OR QuoteNumber like '%' + @QuoteNumber+'%') AND   
				  (IsNull(@CustomerReference,'') ='' OR CustomerReference like '%' + @CustomerReference+'%') AND  
				  (IsNull(@SerialNumber,'') ='' OR SerialNumber like '%' + @SerialNumber+'%') AND
				  (ISNULL(@LastMSLevel,'') ='' OR AllMSlevels like '%' + @LastMSLevel+'%') and
				  (IsNull(@StockType,'') ='' OR StockType like '%' + @StockType+'%')   AND
				  (IsNull(@Status,'') ='' OR InvoiceStatus like '%' + @Status+'%')
				  ))
				   SELECT @Count = COUNT(InvoicingId) from #TempResults     

				   SELECT *, @Count As NumberOfItems FROM #TempResults 
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