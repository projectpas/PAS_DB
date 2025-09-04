/*************************************************************             
 ** File:   [dbo.usprpt_GetSOOperatingMetricReport_NotQuotedPart]             
 ** Author:  Rajesh Gami    
 ** Description: Get Data for Salesorder Operating Metric Report by NOT Quoted Part
 ** Purpose:           
 ** Date:   04-Sep-2025         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    04-Sep-2025  Rajesh Gami   Created 
**************************************************************/  
CREATE     PROCEDURE [dbo].[usprpt_GetSOOperatingMetricReport_NotQuotedPart] 
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
		DECLARE @customerName varchar(MAX) = NULL,  @sourceById varchar(40) = NULL , @sourceByName varchar(40) = NULL,  
		@fromdate datetime,@todate datetime, @partNumber varchar(max) = NULL,@noQuoteId INT =2,
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
  
	  SET @IsDownload = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 1 ELSE 0 END
	   SELECT 
		@fromdate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='From Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @fromdate end,
		@todate=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='To Date' 
		then convert(Date,filterby.value('(FieldValue/text())[1]','VARCHAR(100)')) else @todate end,
		
		@customerName=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Customer(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @customerName end,
		
		@sourceById=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='Quote Source' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @sourceById end,

		@Count=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='defaultRecord' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @Count end,
		
		@partNumber=case when filterby.value('(FieldName/text())[1]','VARCHAR(100)')='PN(Optional)' 
		then filterby.value('(FieldValue/text())[1]','VARCHAR(100)') else @partNumber end,

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

	
	 SELECT * INTO #TempSOOperating FROM
      (SELECT 
			 UPPER(rfq.BuyerName) 'customer',  
			CASE WHEN eRFQ.CustomerRfqPartMappingId IS NULL THEN UPPER(rfq.LinePartNumber) ELSE UPPER(eRFQ.PartNumber) END AS 'pn',  
			CASE WHEN eRFQ.CustomerRfqPartMappingId IS NULL THEN UPPER(rfq.LineDescription) ELSE UPPER(eRFQ.PartDescription) END AS 'pnDescription',  
			'' as 'type',
			CASE WHEN eRFQ.CustomerRfqPartMappingId IS NULL THEN UPPER(rfq.Condition) ELSE UPPER(eRFQ.Condition) END AS 'condition',  
			CASE WHEN eRFQ.CustomerRfqPartMappingId IS NULL THEN rfq.Quantity ELSE eRFQ.Quantity END AS 'qty',  
			rfq.RFQID as 'rfqReference',
			ipm.Code as 'sourceBy',
			rfQuote.UpdatedDate
       FROM dbo.CustomerRfq rfq WITH (NOLOCK)
			LEFT JOIN dbo.CustomerRfqQuote rfQuote WITH (NOLOCK) ON rfq.RfqId = rfQuote.RfqId
			LEFT JOIN dbo.CustomerRfqPartMapping eRFQ WITH(NOLOCK) ON rfq.CustomerRfqId = eRFQ.CustomerRfqId
			LEFT JOIN dbo.IntegrationPortalMaster ipm WITH(NOLOCK) On ipm.IntegrationPortalMasterId = rfq.IntegrationPortalId
		  WHERE 
				ISNULL(rfq.IsQuote,0) = @noQuoteId 
					AND (@customerName IS NULL OR rfq.BuyerName LIKE '%' + @customerName + '%')
					 AND (
						  @partNumber IS NULL 
						  OR (eRFQ.CustomerRfqPartMappingId IS NOT NULL AND eRFQ.PartNumber LIKE '%' + @partNumber + '%')
						  OR (eRFQ.CustomerRfqPartMappingId IS NULL AND rfq.LinePartNumber LIKE '%' + @partNumber + '%')
						)
					AND rfq.IntegrationPortalId = ISNULL(@sourceById,rfq.IntegrationPortalId) 
					AND CAST(rfQuote.UpdatedDate AS DATE) BETWEEN CAST(@fromdate AS DATE) AND CAST(@todate AS DATE) AND rfq.mastercompanyid = @mastercompanyid
		) AS a

		SELECT * INTO #tmpFinalResult FROM (SELECT * FROM #TempSOOperating main) AS res

		SET @totalResult = (SELECT COUNT(*) FROM #tmpFinalResult)
		SET @Sql = N'Select TOP '+@Count+' (CASE WHEN '+@totalResult+' > '+@Count+' THEN '+@Count+' ELSE '+@totalResult+' END) AS totalRecordsCount,* from #tmpFinalResult ORDER by UpdatedDate DESC'

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
            @AdhocComments varchar(150) = '[dbo.usprpt_GetSOOperatingMetricReport_NotQuotedPart]',  
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