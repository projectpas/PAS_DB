﻿/*************************************************************             
 ** File:   [dbo.usprpt_GetWOOperatingMetricReport_QuotedUnit]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for Workorder Operating Metric Report by Most Quoted WO
 ** Purpose:           
 ** Date:   19-Mar-2024         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    19-Mar-2024  Rajesh Gami   Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[usprpt_GetWOOperatingMetricReport_QuotedUnit] 
@PageNumber int = 1,
@PageSize int = NULL,
@mastercompanyid int,
@xmlFilter XML
 
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
		SET @PageSize = 50;
		DECLARE @Count VARCHAR(10)='50',@Sql NVARCHAR(MAX);  
		DECLARE @customerid varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@workscopeIds varchar(200) = NULL,
		@itemMasterId varchar(40) = NULL,
		@searchWOType varchar(10) = NULL,
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
		@woqApprovedId int = (SELECT TOP 1 WorkOrderQuoteStatusId FROM DBO.WorkOrderQuoteStatus WITH(NOLOCK) WHERE Description = 'Approved'),
		@totalResult VARCHAR(10) = 0

  
  BEGIN TRY  
    --BEGIN TRANSACTION  
       print 'Start'
      DECLARE @ModuleID INT = 12; -- MS Module ID
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		
		@customerid=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerid end,
		
		@workscopeIds=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Work Scope' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @workscopeIds end,
		
		@Count=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='defaultRecord' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Count end,
		
		@searchWOType=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='searchWOType' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @searchWOType end,
		
		@itemMasterId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='MPN(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @itemMasterId end,

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
		  SET @isCustomerWO = (CASE WHEN @searchWOType = '5' THEN 1 ELSE 0 END)
		  SET @Count = COALESCE(NULLIF(@Count, 0), 50);
		 SET @woTypeIds = 
						CASE 
							WHEN @isCustomerWO = 1 THEN 
								(SELECT STRING_AGG(Id, ',') FROM dbo.WorkOrderType WHERE Description = 'Customer')
							ELSE 
								(SELECT STRING_AGG(Id, ',') FROM dbo.WorkOrderType WHERE Description != 'Customer')
						END;
	 
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
	 
	 SELECT * INTO #TempWOOperating FROM
      (SELECT 
			UPPER(Customer.Name) 'customer',  
			WO.CustomerId CustomerId,
			ROW_NUMBER() OVER(Partition by IM.ItemMasterId ORDER BY IM.PartNumber) AS Row_Number,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pnDescription',  
			--UPPER(WS.WorkScopeCode) 'workscopes',
			UPPER(CN.Description) 'workscopes',
			CASE WHEN WOBIT.WOBillingInvoicingItemId IS NULL THEN 
				CASE WHEN ISNULL(WOQD.QuoteMethod, 0) = 1 THEN ISNULL(WOQD.CommonFlatRate , 0) ELSE  
			    ISNULL(ISNULL(ISNULL(WOQD.MaterialFlatBillingAmount,0) + ISNULL(WOQD.LaborFlatBillingAmount,0) + ISNULL(WOQD.ChargesFlatBillingAmount,0)+ ISNULL(WOQD.FreightFlatBillingAmount,0),0) ,0) END
			ELSE ISNULL(WOBIT.GrandTotal,0) END AS revenue,
			--CASE WHEN ISNULL(WOQD.QuoteMethod, 0) = 1 THEN ISNULL( WOQD.CommonFlatRate , 0) ELSE  
			--	ISNULL(ISNULL(WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount+ WOQD.FreightFlatBillingAmount,0) ,0) END 'revenue',  
			UPPER(MSD.Level1Name) AS level1,  
			UPPER(MSD.Level2Name) AS level2, 
			UPPER(MSD.Level3Name) AS level3, 
			UPPER(MSD.Level4Name) AS level4, 
			UPPER(MSD.Level5Name) AS level5, 
			UPPER(MSD.Level6Name) AS level6, 
			UPPER(MSD.Level7Name) AS level7, 
			UPPER(MSD.Level8Name) AS level8, 
			UPPER(MSD.Level9Name) AS level9, 
			UPPER(MSD.Level10Name) AS level10
       FROM 
			DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
			INNER JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK) ON WOPN.ID = WOQD.WOPartNoId and ISNULL(WOQD.IsActive,1)=1  
			INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
			INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID
			--INNER JOIN DBO.WorkOrderMPNCostDetails CST WITH (NOLOCK) ON WOPN.ID = CST.WOPartNoId  
			INNER JOIN dbo.WorkOrder WO WITH(NOLOCK) on WOPN.WorkOrderId = WO.WorkOrderId
			LEFT JOIN DBO.WorkOrderBillingInvoicingItem AS WOBIT WITH (NOLOCK)  on WOPN.ID = WOBIT.WorkOrderPartId AND ISNULL(WOBIT.IsVersionIncrease,0)=0 AND ISNULL(WOBIT.IsPerformaInvoice, 0) = 0 
			LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK) ON WOBIT.BillingInvoicingId = WBI.BillingInvoicingId and WBI.IsVersionIncrease=0 AND ISNULL(WBI.IsPerformaInvoice, 0) = 0  AND WBI.InvoiceStatus = 'Invoiced'
			LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN DBO.Customer WITH (NOLOCK) ON WO.CustomerId = Customer.CustomerId  
			LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.itemmasterId = IM.itemmasterId  
			--LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId
			LEFT JOIN DBO.Condition AS CN WITH (NOLOCK) ON WOPN.RevisedConditionId = CN.ConditionId
		  
		  WHERE 
				--WOQ.QuoteStatusId = @woqApprovedId  AND WBI.InvoiceStatus = 'Invoiced'  AND 
				ISNULL(WOQ.IsDeleted,0) = 0 AND	WO.CustomerId=ISNULL(@customerid,WO.CustomerId)  AND WOPN.ItemMasterId = ISNULL(@itemMasterId,WOPN.ItemMasterId)    
					AND CAST(WOQ.opendate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND WO.mastercompanyid = @mastercompanyid
					AND (ISNULL(@woTypeIds,'')='' OR WO.WorkOrderTypeId IN(SELECT value FROM String_split(ISNULL(@woTypeIds,''), ',')))
					AND (ISNULL(@workscopeIds,'')='' OR WOPN.RevisedConditionId IN(SELECT value FROM String_split(ISNULL(@workscopeIds,''), ',')))
					--AND (ISNULL(@workscopeIds,'')='' OR WOPN.WorkOrderScopeId IN(SELECT value FROM String_split(ISNULL(@workscopeIds,''), ',')))
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

		SELECT * INTO #TempWOOperatingFinal FROM
		 (SELECT (CASE WHEN (SELECT TOP 1 Row_Number FROM #TempWOOperating tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) > 1 THEN (SELECT TOP 1 tm.workscopes FROM #TempWOOperating tm WHERE tm.ItemMasterId = main.ItemMasterId ORDER BY Row_Number DESC) ELSE workscopes END) AS 'workscope',* FROM #TempWOOperating main) as res

		SELECT * INTO #tmpFinalResult FROM
		 (SELECT workscope,MAX(Row_Number) AS timesQuoted,SUM(revenue) AS totalRevenue, CONVERT(DECIMAL(10,2),(SUM(revenue)/MAX(Row_Number))) as averageRevenue,pn,pnDescription,ItemMasterId
		 
		 FROM #TempWOOperatingFinal GROUP BY pn,pnDescription,workscope,ItemMasterId) as result
		SET @totalResult = (SELECT COUNT(*) FROM #tmpFinalResult)
		--Select TOP 25 (CASE WHEN @totalResult > 25 THEN 25 ELSE @totalResult END) AS totalRecordsCount,* from #tmpFinalResult ORDER by timesQuoted DESC
		SET @Sql = N'Select TOP '+@Count+' (CASE WHEN '+@totalResult+' > '+@Count+' THEN '+@Count+' ELSE '+@totalResult+' END) AS totalRecordsCount,* from #tmpFinalResult ORDER by timesQuoted DESC'

		PRINT @Sql
		EXEC sp_executesql  @Sql, N'@Count INT, @totalResult INT OUTPUT', @Count = @Count,@totalResult = @totalResult OUTPUT;

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
            @AdhocComments varchar(150) = '[dbo.usprpt_GetWOOperatingMetricReport_QuotedUnit]',  
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