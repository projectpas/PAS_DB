/*************************************************************               
 ** File:   [usprpt_GetWorkOrderBacklogReportSSRSData]               
 ** Author:   Devendra Shekh      
 ** Description: Get Data for WorkOrderBacklog Report  new SP 
 ** Purpose:             
 ** Date:   19th April 2024     
              
 ** PARAMETERS:               
             
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** S NO   Date         Author				Change Description                
 ** --   --------     -------			--------------------------------     
 **	1	19-04-2022   Devendra Shekh			created    
 
exec usprpt_GetWorkOrderBacklogReportSSRSData 
@mastercompanyid=1,@id='2024-04-15 00:00:00',@id2='2024-04-15 00:00:00',@id3='',@id4='',@id5='',@strFilter='1,5,6,20,22,52,53!2,7,8,9!3,11,10!4,13,12!!!!!!'
**************************************************************/    
CREATE   PROCEDURE [dbo].[usprpt_GetWorkOrderBacklogReportSSRSData]     
	@mastercompanyid INT,
	@id DATETIME2,
	@id2 DATETIME2,
	@id3 VARCHAR(MAX) = NULL,
	@id4 VARCHAR(10) = NULL,
	@id5 VARCHAR(10) = NULL,
	@strFilter VARCHAR(MAX) = NULL
AS    
BEGIN    
  SET NOCOUNT ON;    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
    
  BEGIN TRY    
    BEGIN TRANSACTION    

	IF OBJECT_ID(N'tempdb..#TEMPMSFilter') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPMSFilter
	END

	CREATE TABLE #TEMPMSFilter(        
		ID BIGINT  IDENTITY(1,1),        
		LevelIds VARCHAR(MAX)			 
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
	DECLARE @ModuleID INT = 12; -- MS Module ID 

	SET @id4 = CASE WHEN @id4 = 0 THEN NULL ELSE @id4 END;
	SET @id5 = CASE WHEN @id5 = 0 THEN NULL ELSE @id5 END;

	IF OBJECT_ID(N'tempdb..#TEMPWOBackLogReportRecords') IS NOT NULL    
	BEGIN    
		DROP TABLE #TEMPWOBackLogReportRecords
	END

	CREATE TABLE #TEMPOriginalStocklineRecords(        
		ID BIGINT IDENTITY(1,1),        
		WorkOrderId BIGINT NULL,
		WorkOrderPartNoId BIGINT NULL,
		Customername VARCHAR(50) NULL,
		PN VARCHAR(50) NULL,
		PNdescription VARCHAR(MAX) NULL,
		WONum VARCHAR(30) NULL,
		SerialNum VARCHAR(30) NULL,
		WOType VARCHAR(30) NULL,
		StageCode VARCHAR(30) NULL,
		StatusCode VARCHAR(30) NULL,
		ReceivedDate datetime2 NULL,
		OpenDate datetime2 NULL,
		ApprovedAmount decimal(18, 2) NULL,
		UnitCost decimal(18, 2) NULL,
		StocklineId BIGINT NULL,
		PartsCost decimal(18, 2) NULL,
		LaborCost decimal(18, 2) NULL,
		OverheadCost decimal(18, 2) NULL,
		MiscCharge decimal(18, 2) NULL,
		Othercost decimal(18, 2) NULL,
		Total decimal(18, 2) NULL,
		WODaysCount BIGINT NULL,
		Techname VARCHAR(50) NULL,
		Priority VARCHAR(50) NULL,
		WorkScope VARCHAR(50) NULL,
		QuoteAmount decimal(18, 2) NULL,
		DaysInStage BIGINT NULL,
		level1 VARCHAR(500) NULL,
		level2 VARCHAR(500) NULL,
		level3 VARCHAR(500) NULL,
		level4 VARCHAR(500) NULL,
		level5 VARCHAR(500) NULL,
		level6 VARCHAR(500) NULL,
		level7 VARCHAR(500) NULL,
		level8 VARCHAR(500) NULL,
		level9 VARCHAR(500) NULL,
		level10 VARCHAR(500) NULL,
		MasterCompanyId int NULL
	) 

	INSERT INTO #TEMPOriginalStocklineRecords(WorkOrderId,WorkOrderPartNoId, Customername, PN, PNdescription, WONum, SerialNum, WOType, StageCode, StatusCode, ReceivedDate, OpenDate, ApprovedAmount, UnitCost, StocklineId, PartsCost, LaborCost, OverheadCost,  
				MiscCharge, Othercost, Total, WODaysCount, Techname, Priority, WorkScope, QuoteAmount, DaysInStage, level1, level2, level3, level4, level5, level6, level7, level8, level9, level10, MasterCompanyId)  
    SELECT    
    WO.WorkOrderId,  
	WOWF.WorkOrderPartNoId,
    UPPER(C.Name) 'Customername',  
    UPPER(IM.partnumber) 'PN',    
    UPPER(IM.PartDescription) 'PNdescription',    
    UPPER(WO.WorkOrderNum) 'WONum',    
    UPPER(SL.SerialNumber) 'SerialNum',    
    UPPER(WOT.Description) 'WOType',    
    UPPER(WOS.Stage) 'StageCode',    
    UPPER(WOSS.Description) 'StatusCode',    
    CONVERT(VARCHAR(50), WOPN.ReceivedDate, 107) 'ReceivedDate',     
    CONVERT(VARCHAR(50), (select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)), 107) 'OpenDate',    
    CASE WHEN ISNULL(WQD.QuoteMethod,0) = 0 THEN ISNULL((WQD.MaterialFlatBillingAmount + WQD.LaborFlatBillingAmount + WQD.ChargesFlatBillingAmount + WQD.FreightFlatBillingAmount),0.00) ELSE ISNULL(WQD.CommonFlatRate,0.00) END 'ApprovedAmount',  
    ISNULL(SL.purchaseorderUnitCost, 0) 'UnitCost',    
    RCW.StocklineId,    
    CASE WHEN ISNULL(WOBI.WOBillingInvoicingItemId, 0) = 0 THEN CAST(ISNULL(WOC.PartsCost, 0) AS VARCHAR(20)) ELSE CAST(ISNULL(WOBI.MaterialCost, 0) AS VARCHAR(20)) END'PartsCost',     
    ISNULL(WOC.LaborCost, 0) 'LaborCost',    
    ISNULL(WOC.OverheadCost, 0) 'OverheadCost',    
    CASE WHEN ISNULL(WOBI.WOBillingInvoicingItemId, 0) = 0 THEN ISNULL(WOC.ChargesCost, 0) + ISNULL(WOC.FreightCost, 0) ELSE ISNULL(WOBI.MiscCharges, 0) + ISNULL(WOBI.Freight, 0) END 'MiscCharge',    
    CASE WHEN ISNULL(WOBI.WOBillingInvoicingItemId, 0) = 0 THEN ISNULL(WOC.Othercost, 0) ELSE ISNULL(WOBI.MiscCharges, 0) END 'Othercost',    
    ((CASE WHEN ISNULL(WOBI.WOBillingInvoicingItemId, 0) = 0 THEN ISNULL(WOC.PartsCost, 0) ELSE ISNULL(WOBI.MaterialCost, 0) END) + ISNULL(WOC.LaborCost, 0) + ISNULL(WOC.OverheadCost, 0) + (CASE WHEN ISNULL(WOBI.WOBillingInvoicingItemId, 0) = 0 THEN ISNULL(WOC.Othercost, 0) ELSE ISNULL(WOBI.MiscCharges, 0) END)) 'Total',    
    ISNULL(DATEDIFF(DAY, RCW.ReceivedDate, GETDATE()), 0) AS 'WODaysCount',    
    ISNULL(UPPER(E.FirstName + ' ' + E.LastName), '') 'Techname',    
	UPPER(ISNULL(P.[Description], '')) AS 'Priority',
	UPPER(ISNULL(WS.[WorkScopeCodeNew], '')) AS 'WorkScope',
	CASE WHEN ISNULL(WQD.QuoteMethod,0) = 0 THEN ISNULL((WQD.MaterialFlatBillingAmount + WQD.LaborFlatBillingAmount + WQD.ChargesFlatBillingAmount + WQD.FreightFlatBillingAmount),0.00) ELSE ISNULL(WQD.CommonFlatRate,0.00) END 'QuoteAmount',
	0 AS 'DaysInStage',
    UPPER(MSD.Level1Name) AS level1,      
    UPPER(MSD.Level2Name) AS level2,     
    UPPER(MSD.Level3Name) AS level3,     
    UPPER(MSD.Level4Name) AS level4,     
    UPPER(MSD.Level5Name) AS level5,     
    UPPER(MSD.Level6Name) AS level6,     
    UPPER(MSD.Level7Name) AS level7,     
    UPPER(MSD.Level8Name) AS level8,     
    UPPER(MSD.Level9Name) AS level9,     
    UPPER(MSD.Level10Name) AS level10 ,  
    WO.MasterCompanyId  
   FROM DBO.WorkOrder WO WITH (NOLOCK)      
    INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId     
    INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID    
    INNER JOIN DBO.ItemMaster AS IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId    
    INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID    
    LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId   
    LEFT JOIN DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK) ON WOQ.WorkOrderQuoteId = WQD.WorkOrderQuoteId  
    LEFT JOIN DBO.Customer C WITH (NOLOCK) ON C.CustomerId = WO.CustomerId  
    LEFT JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK) ON WOPN.ID = WOC.WOPartNoId    
    LEFT JOIN DBO.Stockline SL WITH (NOLOCK) ON WOPN.StockLineId = SL.StockLineId AND SL.IsParent = 1    
    LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID    
    LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK) ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId    
    LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WOSS.Id    
    LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)ON WO.WorkOrderTypeId = WOT.Id            
    LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK) ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId        
    LEFT JOIN DBO.Employee E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId 
    LEFT JOIN DBO.[Priority] P WITH (NOLOCK) ON WOPN.WorkOrderPriorityId = P.PriorityId 
    LEFT JOIN DBO.[WorkScope] WS WITH (NOLOCK) ON WOPN.WorkOrderScopeId = WS.WorkScopeId   
	LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
	LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
	LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
	LEFT JOIN [dbo].WorkOrderBillingInvoicingItem WOBI WITH(NOLOCK) ON WOPN.ID = WOBI.WorkOrderPartId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0

   WHERE CAST((select [dbo].[ConvertUTCtoLocal] (WO.OpenDate,TZ.Description)) AS DATE) BETWEEN CAST(@id AS DATE) AND CAST(@id2 AS DATE)    
    AND (ISNULL(@id5,'') ='' OR WOT.Id = ISNULL(@id5,WOT.Id)) AND ISNULL(WO.IsDeleted, 0) = 0 AND ISNULL(WO.IsActive, 1) = 1 AND ISNULL(WO.WorkOrderStatusId, 0) != 2 --WO Not Closed  
    AND  ISNULL(WOPN.WorkOrderStatusId, 0) != 2 AND  ISNULL(WOPN.IsClosed, 0) != 1 --MPN Not Closed  
    AND (ISNULL(@id3,'') ='' OR WOS.WorkOrderStageId IN(SELECT value FROM String_split(ISNULL(@id3,WOS.WorkOrderStageId), ',')))     
    AND (ISNULL(@id4,'') ='' OR WOSS.Id = ISNULL(@id4,WOSS.Id)) 
    AND WO.MasterCompanyId = @mastercompanyid 
    AND (ISNULL(@Level1,'') ='' OR MSD.[Level1Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level1,',')))    
    AND (ISNULL(@Level2,'') ='' OR MSD.[Level2Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level2,',')))    
    AND (ISNULL(@Level3,'') ='' OR MSD.[Level3Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level3,',')))    
    AND (ISNULL(@Level4,'') ='' OR MSD.[Level4Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level4,',')))    
    AND (ISNULL(@Level5,'') ='' OR MSD.[Level5Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level5,',')))    
    AND (ISNULL(@Level6,'') ='' OR MSD.[Level6Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level6,',')))    
    AND (ISNULL(@Level7,'') ='' OR MSD.[Level7Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level7,',')))    
    AND (ISNULL(@Level8,'') ='' OR MSD.[Level8Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level8,',')))    
    AND (ISNULL(@Level9,'') ='' OR MSD.[Level9Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level9,',')))    
    AND  (ISNULL(@Level10,'') =''  OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@Level10,',')))  
     
	 UPDATE  #TEMPOriginalStocklineRecords SET DaysInStage = tmpDaysData.DaysInStage
			FROM( SELECT WTA.WorkOrderPartNoId,
						 CASE WHEN WTA.StatusChangedEndDate IS NULL THEN ISNULL(DATEDIFF(day, (WTA.StatusChangedDate), GETDATE()), 0) 
								ELSE (ISNULL(((WTA.[Days])+ ((WTA.[Hours])/24)+ ((WTA.[Mins])/1440)),0)) END AS 'DaysInStage'
			FROM [DBO].[WorkOrderTurnArroundTime] WTA WITH(NOLOCK)
			LEFT JOIN [DBO].[WorkOrderStage] WOSD WITH(NOLOCK) ON WTA.CurrentStageId = WOSD.WorkOrderStageId
			GROUP BY WTA.WorkOrderPartNoId, WTA.StatusChangedEndDate, WTA.StatusChangedDate, WTA.[Days], WTA.[Hours], WTA.[Mins]
			) tmpDaysData WHERE tmpDaysData.WorkOrderPartNoId = #TEMPOriginalStocklineRecords.WorkOrderPartNoId
    
    SELECT COUNT(WorkOrderId) OVER () AS TotalRecordsCount, * FROM #TEMPOriginalStocklineRecords ORDER BY WorkOrderId DESC  

    COMMIT TRANSACTION    
  END TRY    
    
  BEGIN CATCH    
  ROLLBACK TRANSACTION    
    DECLARE @ErrorLogID int,    
            @DatabaseName varchar(100) = DB_NAME()    
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            ,    
            @AdhocComments varchar(150) = 'usprpt_GetWorkOrderBacklogReportSSRSData',    
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@id, '') AS varchar(100)) +    
            '@Parameter3 = ''' + CAST(ISNULL(@id2, '') AS varchar(100)) +    
            '@Parameter4 = ''' + CAST(ISNULL(@id3, '') AS varchar(100)) +    
            '@Parameter5 = ''' + CAST(ISNULL(@id4, '') AS varchar(100)) +    
            '@Parameter6 = ''' + CAST(ISNULL(@id5, '') AS varchar(100)) +    
            '@Parameter7 = ''' + CAST(ISNULL(@strFilter, '') AS varchar),    
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