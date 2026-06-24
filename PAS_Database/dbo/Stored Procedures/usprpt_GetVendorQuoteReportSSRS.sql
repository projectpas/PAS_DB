/*************************************************************               
 ** File:  [usprpt_GetVendorQuoteReportSSRS]      
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to get the Vendor Quote Details
 ** Purpose:             
 ** Date:   07-October-2025          
              
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date				Author				Change Description                
 ** --   --------			-------				--------------------------------              
    1    07-October-2025	Devendra Shekh		Created    
    2	 23-06-2026         Ayushi Patel		[PN-16927]UOM changes    
exec usprpt_GetVendorQuoteReportSSRS @mastercompanyid=1,@id='2026-06-23',@id2='2026-06-23',@id3='',@id4='',@id5='',@strFilter='1,5,6!2,7,8,9!3,11,10!4,12,13!!!!!!'
************************************************************************/ 
CREATE   PROCEDURE [dbo].[usprpt_GetVendorQuoteReportSSRS]
	@mastercompanyid INT,
	@id DATETIME2,
	@id2 DATETIME2,
	@id3 VARCHAR(300) = NULL,
	@id4 VARCHAR(300) = NULL,
	@id5 VARCHAR(300) = NULL,
	@strFilter VARCHAR(MAX) = NULL 
AS  
BEGIN  
SET NOCOUNT ON;  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
BEGIN TRY 
	
	IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END

	CREATE TABLE #TEMPMSFilter(        
		ID BIGINT  IDENTITY(1,1),        
		LevelIds VARCHAR(MAX)			 
	) 

	IF OBJECT_ID(N'tempdb..#tmp_QuoteResult') IS NOT NULL    
	BEGIN    
		DROP TABLE #tmp_QuoteResult
	END

	CREATE TABLE #tmp_QuoteResult (
		[RowId] [bigint] IDENTITY(1,1) NOT NULL,
		[ModuleId] [bigint] NULL,
		[ReferenceId] [bigint] NULL,
		[PartReferenceId] [bigint] NULL,
		[POROId] [bigint] NULL,
		[PartNumber] [varchar](250) NULL,
		[PNDescription] [varchar](MAX) NULL,
		[QuoteNum] [varchar](100) NULL,
		[QuoteDate] [datetime2] NULL,
		[Vendor] [varchar](100) NULL,
		[QuoteSource] [varchar](50) NULL,
		[SourceRef] [varchar](50) NULL,
		[UOM] [varchar](50) NULL,
		[Condition] [varchar](256) NULL,
		[Qty] [decimal](18, 6) NULL,
		[UnitCost] [decimal](18, 6) NULL,
		[Amount] [decimal](18, 6) NULL,
		[ReferenceNum] [varchar](100) NULL,
		[ReferenceStatus] [varchar](50) NULL,
		[Notes] [varchar](MAX) NULL,
		[level1] [varchar](500) NULL,
		[level2] [varchar](500) NULL,
		[level3] [varchar](500) NULL,
		[level4] [varchar](500) NULL,
		[level5] [varchar](500) NULL,
		[level6] [varchar](500) NULL,
		[level7] [varchar](500) NULL,
		[level8] [varchar](500) NULL,
		[level9] [varchar](500) NULL,
		[level10] [varchar](500) NULL,
		[MasterCompanyId] [int] NULL,
	)

	INSERT INTO #TEMPMSFilter(LevelIds)
	SELECT Item FROM DBO.SPLITSTRING(@strFilter,'!')

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
	@Level10 VARCHAR(MAX) = NULL ;

	DECLARE @VRFQPOMSModuleID BIGINT, @VRFQROMSModuleID BIGINT, @VRFQPO INT, @VRFQRO INT;

	SELECT @VRFQPO = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';
	SELECT @VRFQRO = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQRepairOrder';
	SELECT @VRFQPOMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPOPart';
	SELECT @VRFQROMSModuleID = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQROPart';

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

	SET @id3 = CASE WHEN ISNULL(@id3, '') = '' THEN NULL ELSE TRIM(@id3) END;
	SET @id4 = CASE WHEN @id4 = 0 OR ISNULL(@id4, '') = '' THEN NULL ELSE @id4 END;
	SET @id5 = CASE WHEN @id5 = 0 OR ISNULL(@id5, '') = '' THEN NULL ELSE @id5 END;

	--	Vendor RFQ Purchase Order Details
	INSERT INTO #tmp_QuoteResult
		SELECT
		@VRFQPO AS [ModuleId],
		VPOP.VendorRFQPurchaseOrderId,
		VPOP.VendorRFQPOPartRecordId,
		VPOP.PurchaseOrderId,
		UPPER(VPOP.PartNumber),
		UPPER(VPOP.PartDescription),
		UPPER(PO.VendorRFQPurchaseOrderNumber),
		PO.OpenDate,
		UPPER(PO.VendorName),
		UPPER(CASE WHEN ISNULL(PO.SourceBy, '') = '' THEN 'PAS' ELSE PO.SourceBy END),
		UPPER(PO.MarketplaceRef),
		UPPER(VPOP.UnitOfMeasure),
		UPPER(VPOP.Condition),       
		VPOP.QuantityOrdered,       
		VPOP.UnitCost,       
		VPOP.ExtendedCost,   
		UPPER(VPOP.PurchaseOrderNumber),
		UPPER('') ReferenceStatus,
		UPPER(CAST('<root>' +
		  REPLACE(
			REPLACE(
			  REPLACE(
				REPLACE(ISNULL(VPOP.Memo, ''), '</p><p>', CHAR(13)+CHAR(10)),
			  '<br/>', CHAR(13)+CHAR(10)),
			'<br>', CHAR(13)+CHAR(10)),
		  '&', '&amp;') +
		  '</root>' AS XML
		).value('string((/root)[1])', 'nvarchar(max)')),
		UPPER(MSD.Level1Name), 
		UPPER(MSD.Level2Name),
		UPPER(MSD.Level3Name),
		UPPER(MSD.Level4Name),
		UPPER(MSD.Level5Name),
		UPPER(MSD.Level6Name),
		UPPER(MSD.Level7Name),
		UPPER(MSD.Level8Name),
		UPPER(MSD.Level9Name),
		UPPER(MSD.Level10Name),
		PO.MasterCompanyId
	FROM [dbo].[VendorRFQPurchaseOrderPart] VPOP WITH (NOLOCK)  
	INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH (NOLOCK) ON VPOP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId                            
	INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @VRFQPOMSModuleID AND MSD.ReferenceID = VPOP.VendorRFQPOPartRecordId 
	WHERE 
	PO.IsDeleted = 0 AND PO.IsActive = 1
	AND PO.MasterCompanyId = @mastercompanyid   
	AND CAST(PO.OpenDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE)  
	AND (@id3 IS NULL OR TRIM(PO.VendorRFQPurchaseOrderNumber) = @id3)
	AND (@id4 IS NULL OR PO.VendorId = @id4)
	AND (@id5 IS NULL OR VPOP.ItemMasterId = @id5)
    AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
    AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
    AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
    AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
    AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
    AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
    AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
    AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
    AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
    AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
    
	UPDATE TMP
	SET TMP.ReferenceStatus = UPPER(PO.[Status])
	FROM #tmp_QuoteResult TMP
	INNER JOIN [dbo].[PurchaseOrder] PO ON TMP.POROId = PO.PurchaseOrderId AND TMP.ModuleId = @VRFQPO


	--	Vendor RFQ Repair Order Details
	INSERT INTO #tmp_QuoteResult
		SELECT
		@VRFQRO AS [ModuleId],
		VROP.VendorRFQRepairOrderId,
		VROP.VendorRFQROPartRecordId,
		VROP.RepairOrderId,
		UPPER(VROP.PartNumber),
		UPPER(VROP.PartDescription),
		UPPER(RO.VendorRFQRepairOrderNumber),
		RO.OpenDate,
		UPPER(RO.VendorName),
		'PAS' SourceBy,
		'' MarketplaceRef,
		UPPER(VROP.UnitOfMeasure),
		UPPER(VROP.Condition),       
		VROP.QuantityOrdered,       
		VROP.UnitCost,       
		VROP.ExtendedCost,   
		UPPER(VROP.RepairOrderNumber),
		UPPER('') ReferenceStatus,
		UPPER(CAST('<root>' +
		  REPLACE(
			REPLACE(
			  REPLACE(
				REPLACE(ISNULL(VROP.Memo, ''), '</p><p>', CHAR(13)+CHAR(10)),
			  '<br/>', CHAR(13)+CHAR(10)),
			'<br>', CHAR(13)+CHAR(10)),
		  '&', '&amp;') +
		  '</root>' AS XML
		).value('string((/root)[1])', 'nvarchar(max)')),
		UPPER(MSD.Level1Name), 
		UPPER(MSD.Level2Name),
		UPPER(MSD.Level3Name),
		UPPER(MSD.Level4Name),
		UPPER(MSD.Level5Name),
		UPPER(MSD.Level6Name),
		UPPER(MSD.Level7Name),
		UPPER(MSD.Level8Name),
		UPPER(MSD.Level9Name),
		UPPER(MSD.Level10Name),
		RO.MasterCompanyId
	FROM [dbo].[VendorRFQRepairOrderPart] VROP WITH (NOLOCK)  
	INNER JOIN [dbo].[VendorRFQRepairOrder] RO WITH (NOLOCK) ON VROP.VendorRFQRepairOrderId = RO.VendorRFQRepairOrderId
	INNER JOIN [dbo].[RepairOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @VRFQROMSModuleID AND MSD.ReferenceID = VROP.VendorRFQROPartRecordId
	WHERE 
	RO.IsDeleted = 0 AND RO.IsActive = 1
	AND RO.MasterCompanyId = @mastercompanyid   
	AND CAST(RO.OpenDate AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE)  
	AND (@id3 IS NULL OR TRIM(RO.VendorRFQRepairOrderNumber) = @id3)
	AND (@id4 IS NULL OR RO.VendorId = @id4)
	AND (@id5 IS NULL OR VROP.ItemMasterId = @id5)
    AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))
    AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
    AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
    AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
    AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
    AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
    AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
    AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
    AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
    AND (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))

	UPDATE TMP
	SET TMP.ReferenceStatus = UPPER(RO.[Status])
	FROM #tmp_QuoteResult TMP
	INNER JOIN [dbo].[RepairOrder] RO ON TMP.POROId = RO.RepairOrderId AND TMP.ModuleId = @VRFQRO

	--	Select Result 
	SELECT	[RowId], [ModuleId], [ReferenceId], [PartReferenceId], [PartNumber], [PNDescription], [QuoteNum], [QuoteDate], [Vendor], [QuoteSource], [SourceRef], [UOM], [Condition],
			[Qty], [UnitCost], [Amount], [ReferenceNum], [ReferenceStatus], [Notes], [level1], [level2], [level3], [level4], [level5], [level6], [level7], [level8], [level9], [level10],
			[MasterCompanyId] 
	FROM #tmp_QuoteResult ORDER BY [ReferenceId] DESC, [ModuleId] ASC;

END TRY  
BEGIN CATCH
	DECLARE @ErrorLogID int,
		@DatabaseName varchar(100) = DB_NAME(),
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		@AdhocComments varchar(150) = '[usprpt_GetVendorQuoteReportSSRS]',
		@ProcedureParameters varchar(3000) =	'@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(max)),
												@ApplicationName varchar(100) = 'PAS' 
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC Splogexception @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
  
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
		RETURN (1);
	END CATCH
END