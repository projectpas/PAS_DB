/********************************************************************             
 ** File:   [dbo.GetSOOperatingMetricReport_HMarginUnitUnitByIMId]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for SalesOrder Operating Metric Report Highest Margin to Low Margin By Item
 ** Purpose:           
 ** Date:   01-Sep-2025         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
 *********************************************************************            
  ** Change History             
 *********************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    01-Sep-2025  Rajesh Gami   Created  
	2    04-Sep-2025  Rajesh Gami   Remove all taxes from the revenue (Sales and Other Tax)
***********************************************************************/  
CREATE       PROCEDURE [dbo].[GetSOOperatingMetricReport_HMarginUnitUnitByIMId] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET @PageSize = 50;
		DECLARE @Sql NVARCHAR(MAX);  
		DECLARE @customerid varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@itemMasterId varchar(40) = NULL,
		@marginSortBy varchar(50) = NULL,
		@isCustomerWO bit = NULL,
		@woTypeIds varchar(200) = NULL,
		@level1 VARCHAR(MAX) = NULL,
		@level2 VARCHAR(MAX) = NULL,
		@level3 VARCHAR(MAX) = NULL,
		@level4 VARCHAR(MAX) = NULL,
		@Level5 VARCHAR(MAX) = NULL,
		@Level6 VARCHAR(MAX) = NULL,
		@Level7 VARCHAR(MAX) = NULL,
		@Level8 VARCHAR(MAX) = NULL,
		@Level9 VARCHAR(MAX) = NULL,
		@Level10 VARCHAR(MAX) = NULL,
		@IsDownload BIT = NULL,
		@totalResult VARCHAR(10) = 0

  
  BEGIN TRY  
    --BEGIN TRANSACTION  
      DECLARE @MsModuleID INT = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WHERE UPPER(RTRIM(ModuleName)) = 'SALESORDER');
	  DECLARE @SOModuleId INT = ( SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder')
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		
		@customerid=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerid end,
		
		@itemMasterId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='itemMasterId' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @itemMasterId end,

		@marginSortBy=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='marginSortBy' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @marginSortBy end,

		@level1=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level1' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level1 end,
		@level2=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level2' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level2 end,
		@level3=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level3' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level3 end,
		@level4=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level4' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level4 end,
		@level5=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level5' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level5 end,
		@level6=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level6' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level6 end,
		@level7=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level7' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level7 end,
		@level8=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level8' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level8 end,
		@level9=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level9' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level9 end,
		@level10=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Level10' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @level10 end
	  FROM
		  @xmlFilter.nodes('/ArrayOfFilter/Filter')AS TEMPTABLE(filterby)

	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
	  SELECT * INTO #TempWOOperating FROM
      (SELECT 
			UPPER(Customer.Name) 'customer',  
			SO.CustomerId CustomerId,
			ROW_NUMBER() OVER(Partition by IM.ItemMasterId ORDER BY IM.PartNumber) AS Row_Number,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pnDescription',  
			(ISNULL(SOBII.SubTotal,0)) AS totalRevenue,
			(ISNULL(CST.UnitCost,0) * ISNULL(SOBII.QtyBilled,1)) AS partsCost,
			(ISNULL(SOBII.MiscChargesCostPlus,0) + ISNULL(SOBII.SalesTax,0)+ ISNULL(SOBII.OtherTax,0)) AS otherCost,
			((ISNULL(CST.UnitCost,0) * ISNULL(SOBII.QtyBilled,0))  + ISNULL(SOBII.MiscChargesCostPlus,0) + ISNULL(SOBII.SalesTax,0)+ ISNULL(SOBII.OtherTax,0) ) AS totalCost,
			--((ISNULL(SOBII.GrandTotal,0)) - ((ISNULL(CST.UnitCost,0) * ISNULL(SOBII.QtyBilled,0))  + ISNULL(SOBII.MiscChargesCostPlus,0) + ISNULL(SOBII.SalesTax,0)+ ISNULL(SOBII.OtherTax,0)) ) as marginAmount,
			((ISNULL(SOBII.SubTotal,0)) - (ISNULL(CST.UnitCost,0) * ISNULL(SOBII.QtyBilled,1)) ) as marginAmount,
			UPPER(MSD.Level1Name) AS level1,  
			UPPER(MSD.Level2Name) AS level2, 
			UPPER(MSD.Level3Name) AS level3, 
			UPPER(MSD.Level4Name) AS level4, 
			UPPER(MSD.Level5Name) AS level5, 
			UPPER(MSD.Level6Name) AS level6, 
			UPPER(MSD.Level7Name) AS level7, 
			UPPER(MSD.Level8Name) AS level8, 
			UPPER(MSD.Level9Name) AS level9, 
			UPPER(MSD.Level10Name) AS level10,
			SOBI.BillingInvoicingId,
			CN.[Description] AS 'condition',
			SO.SalesOrderNumber AS 'salesOrderNum',
			SOBI.InvoiceDate AS 'invoiceDate',
			SO.OpenDate AS 'openDate',
			SO.SalesOrderId as 'salesOrderId',
			SOBII.StocklineId
       FROM 
			DBO.BillingInvoicingItems AS SOBII WITH (NOLOCK)  
			INNER JOIN DBO.BillingInvoicing AS SOBI WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId and ISNULL(SOBI.IsVersionIncrease,0)=0 AND ISNULL(SOBI.IsPerformaInvoice, 0) = 0  
			INNER JOIN DBO.SalesOrderStocklineV1 SSV WITH(NOLOCK) ON SOBII.SubReferenceId = SSV.SalesOrderPartId AND SSV.StockLineId = SOBII.StocklineId
			INNER JOIN DBO.SalesOrderStockLineCost CST WITH (NOLOCK) ON SOBII.SubReferenceId = CST.SalesOrderPartId  AND SSV.SalesOrderStocklineId = CST.SalesOrderStocklineId
			INNER JOIN DBO.SalesOrder SO WITH (NOLOCK) ON SOBI.ReferenceId = SO.SalesOrderId
			INNER JOIN dbo.SalesOrderPartV1 SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId AND SOBII.SubReferenceId = SOP.SalesOrderPartId
			LEFT JOIN DBO.SalesOrderQuote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId   
			LEFT JOIN DBO.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MsModuleID AND MSD.ReferenceID = SO.SalesOrderId
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Customer WITH (NOLOCK) ON SO.CustomerId = Customer.CustomerId  
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON SOP.itemmasterId = IM.itemmasterId  
			LEFT JOIN DBO.Condition AS CN WITH (NOLOCK) ON SOP.ConditionId = CN.ConditionId 
		  
		  WHERE SOBI.InvoiceStatus = 'Invoiced' AND ISNULL(SO.IsDeleted,0) = 0 AND SOBI.[ModuleId] = @SOModuleId AND
				SO.CustomerId=ISNULL(@customerid,SO.CustomerId)  AND SOP.ItemMasterId = ISNULL(@itemMasterId,SOP.ItemMasterId)   
					AND CAST(SOBI.InvoiceDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND SO.mastercompanyid = @mastercompanyid
					AND  (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
					AND  (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))
					AND  (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))
					AND  (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))
					AND  (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))
					AND  (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))
					AND  (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))
					AND  (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))
					AND  (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))
					AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))
		) as a

		SELECT * INTO #TempSOOperatingFinal FROM (SELECT * FROM #TempWOOperating main) as res
		
		SELECT * INTO #tmpBeforeFinalResult FROM 
					(SELECT t.pn,t.pnDescription,t.ItemMasterId ,totalRevenue, partsCost,otherCost,totalCost,marginAmount,t.condition,salesOrderNum,invoiceDate,openDate,customer,salesOrderId,t.CustomerId,stk.StockLineNumber
					 FROM #TempSOOperatingFinal t LEFT JOIN dbo.Stockline stk WITH(NOLOCK) ON t.StocklineId = stk.StockLineId) as result


		SELECT * INTO #tmpFinalResult FROM
		 (SELECT pn,
				 pnDescription,
				 ItemMasterId,
				 totalRevenue, 
				 partsCost,
				 otherCost,
				 totalCost,
				 marginAmount,	condition,salesOrderNum,invoiceDate,openDate,customer,salesOrderId,CustomerId,StockLineNumber,			
				 (CASE WHEN totalRevenue = 0 THEN 0 ELSE (CONVERT(DECIMAL(10,2),((marginAmount/totalRevenue)*100))) END) as margin,
				 (CASE WHEN totalRevenue = 0 THEN 0 ELSE (CONVERT(DECIMAL(10,2),((partsCost/totalRevenue)*100))) END) as partsOrRev,
				 (CASE WHEN totalRevenue = 0 THEN 0 ELSE (CONVERT(DECIMAL(10,2),((otherCost/totalRevenue)*100))) END) as otherOrRev,
				 (CASE WHEN totalRevenue = 0 THEN 0 ELSE (CONVERT(DECIMAL(10,2),((totalCost/totalRevenue)*100))) END) as totalCostOrRev
				 
		 FROM #tmpBeforeFinalResult) as result

		/********** Get data from high margin to low margin***********/
		IF(@marginSortBy = 'marginPer')
		BEGIN
			SELECT * FROM #tmpFinalResult ORDER by margin DESC
		END
		ELSE
		BEGIN
			SELECT * FROM #tmpFinalResult ORDER by marginAmount DESC
		END
		

  END TRY  
  
  BEGIN CATCH  
      SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(), 
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = '[dbo.GetSOOperatingMetricReport_HMarginUnitUnitByIMId]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS varchar(max)),
            @ApplicationName varchar(100) = 'PAS' 
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
   
END