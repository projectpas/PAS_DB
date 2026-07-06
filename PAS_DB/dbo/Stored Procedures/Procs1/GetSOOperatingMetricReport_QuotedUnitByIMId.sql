/*************************************************************             
 ** File:   [dbo.GetSOOperatingMetricReport_QuotedUnitByIMId]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for Salesorder Operating Metric Report by Most Quoted SO By ItemMaster Id
 ** Purpose:           
 ** Date:   01-Sep-2025         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    01-Sep-2025  Rajesh Gami   Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/  
CREATE     PROCEDURE [dbo].[GetSOOperatingMetricReport_QuotedUnitByIMId] 
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
		DECLARE @customerid varchar(40) = NULL,  @quoteId varchar(40) = NULL,  @sourceById varchar(40) = NULL , @sourceByName varchar(40) = NULL,  
		@fromdate datetime,  
		@todate datetime, 
		@itemMasterId varchar(40) = NULL,
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
  
      DECLARE @ModuleID INT = (SELECT ManagementStructureModuleId FROM dbo.ManagementStructureModule WITH(NOLOCK) WHERE ModuleName = 'SalesOrderQuote')
	  DECLARE @SOQModuleId INT

	  SELECT @SOQModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesQuote';

	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		
		@customerid=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerid end,
		
		@quoteId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='SOQ Num' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @quoteId end,

		@sourceById=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Quote Source' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @sourceById end,

		@Count=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='defaultRecord' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Count end,
		
		@itemMasterId=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='itemMasterId' 
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
		  SET @Count = COALESCE(NULLIF(@Count, 0), 50);
	 
	  SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
	  SET @PageNumber = CASE WHEN NULLIF(@PageNumber,0) IS NULL THEN 1 ELSE @PageNumber END
	 PRINT @sourceById
	 print '@sourceById'
	 if(ISNULL(@sourceById,'0') != '0' )
	 BEGIN
		SET @sourceByName = (select Top 1 CODE From dbo.IntegrationPortalMaster WITH(NOLOCK) WHERE IntegrationPortalMasterId = CAST(@sourceById as INT))
		PRINT @sourceByName
	 END
	 SELECT * INTO #TempSOOperating FROM
      (SELECT 
			UPPER(Customer.[Name]) 'customer',  
			SOQ.CustomerId CustomerId,
			IM.ItemMasterId,
			UPPER(IM.PartNumber) 'pn',  
			UPPER(IM.PartDescription) 'pnDescription',  
			ISNULL(SOQC.UnitSalesPrice,0) AS 'quotePrice',
			ISNULL(SOQC.UnitSalesPriceExtended,0) AS 'extPrice',
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
			CN.[Description] AS 'condition',
			SOQ.SalesOrderQuoteNumber AS 'quoteNumber',
			--BI.InvoiceDate AS 'invoiceDate',
			SOQ.OpenDate AS 'quoteDate',
			SOQ.SalesOrderQuoteId as 'salesOrderId',
			CASE WHEN ISNULL(SOQ.SourceBy,'') = '' THEN 'PAS' ELSE SOQ.SourceBy END as 'source',
			SOQ.VersionNumber as 'versionNum',
			IM.PurchaseUnitOfMeasure as 'uom',
			(CASE WHEN IM.IsOEM = 1 THEN 'OEM' WHEN IM.IsPma = 1  THEN 'PMA' WHEN IM.IsDER =1 THEN 'DER' ELSE 'OEM' END) as 'type',
			SOQP.QtyQuoted as 'qtyQuoted',
			CASE WHEN ISNULL(SO.SalesOrderQuoteId,0) > 0 THEN 'YES' ELSE 'NO' END 'isSOConverted',
			SOQ.CreatedBy as 'quoteBy',
			rfq.RFQID as 'rfqRef'

			FROM dbo.SalesOrderQuotePartV1 SOQP WITH (NOLOCK)
			INNER JOIN SalesOrderQuotePartCost SOQC WITH (NOLOCK) on SOQP.SalesOrderQuotePartId = SOQC.SalesOrderQuotePartId
			INNER JOIN [dbo].[SalesOrderQuote] SOQ WITH (NOLOCK) ON SOQP.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			LEFT JOIN dbo.CustomerRfq  rfq WITH (NOLOCK) ON SOQ.SalesOrderQuoteId = rfq.ReferenceId AND rfq.ModuleId = @SOQModuleId
			LEFT JOIN [dbo].[SalesOrder] SO WITH(NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
			--LEFT JOIN [dbo].[SalesOrderPartV1] SOP WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
			--LEFT JOIN dbo.SalesOrderPartCost SOC WITH (NOLOCK) ON SOP.SalesOrderPartId = SOC.SalesOrderPartId

			LEFT JOIN DBO.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = SOQ.SalesOrderQuoteId
			--LEFT JOIN [dbo].[BillingInvoicingItems] AS SOBII WITH (NOLOCK) ON SOP.SalesOrderPartId = SOBII.SubReferenceId AND ISNULL(SOBII.IsVersionIncrease,0)=0 AND ISNULL(SOBII.IsPerformaInvoice, 0) = 0  AND SOBII.[ModuleId] = @SOModuleId
			--LEFT JOIN [dbo].[BillingInvoicing] AS BI WITH (NOLOCK) ON SOBII.BillingInvoicingId = BI.BillingInvoicingId and BI.IsVersionIncrease=0 AND ISNULL(BI.IsPerformaInvoice, 0) = 0  AND BI.InvoiceStatus = 'Invoiced' AND BI.[ModuleId] = @SOModuleId
			LEFT JOIN [dbo].[EntityStructureSetup] ES ON ES.EntityStructureId=MSD.EntityMSID
			LEFT JOIN [dbo].[Customer] WITH (NOLOCK) ON SOQ.CustomerId = Customer.CustomerId  
			LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SOQP.itemmasterId = IM.itemmasterId  
			 AND ISNULL(IM.IsNonStock,0) = 0 LEFT JOIN DBO.Condition AS CN WITH (NOLOCK) ON SOQP.ConditionId = CN.ConditionId 
		  WHERE 
				ISNULL(SOQ.IsDeleted,0) = 0 AND	SOQ.CustomerId=ISNULL(@customerid,SOQ.CustomerId)  AND SOQP.ItemMasterId = ISNULL(@itemMasterId,SOQP.ItemMasterId) 
				--AND SOQ.SourceBy=ISNULL(@sourceByName,SOQ.SourceBy) 
				AND ( @sourceByName IS NULL OR (@sourceByName = 'PAS'  AND ISNULL(NULLIF(LTRIM(RTRIM(SOQ.SourceBy)), ''), 'PAS') = 'PAS') OR (@sourceByName <> 'PAS' AND SOQ.SourceBy=ISNULL(@sourceByName,SOQ.SourceBy)))
					AND	SOQ.SalesOrderQuoteId=ISNULL(@quoteId,SOQ.SalesOrderQuoteId) 
					AND CAST(SOQ.opendate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND SOQ.mastercompanyid = @mastercompanyid
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
		) AS a

		SELECT * FROm #TempSOOperating ORDER BY quoteDate desc


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
            @AdhocComments varchar(150) = '[dbo.GetSOOperatingMetricReport_QuotedUnitByIMId]',  
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