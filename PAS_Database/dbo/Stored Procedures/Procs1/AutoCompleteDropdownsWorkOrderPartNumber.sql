
/*************************************************************           
 ** File:   [AutoCompleteDropdownsInternalWOPartNumber]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Stockline List for WO MPN    
 ** Purpose:         
 ** Date:   05/30/2023      
          
 ** PARAMETERS: @UserType varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/30/2023   Hemant Saliya Created
     
EXEC dbo.AutoCompleteDropdownsWorkOrderPartNumber @StartWith=default,@Idlist=N'160489',@customerId=2450,@WorkOrderId=0,@WorkOrderTypeId=2,@MasterCompanyId=1
exec dbo.AutoCompleteDropdownsWorkOrderPartNumber @StartWith=default,@Idlist=N'1',@customerId=92,@WorkOrderId=0,@WorkOrderTypeId=1,@MasterCompanyId=1
exec dbo.AutoCompleteDropdownsWorkOrderPartNumber @StartWith=default,@Idlist=N'0',@customerId=92,@WorkOrderId=0,@WorkOrderTypeId=1,@MasterCompanyId=1
**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsWorkOrderPartNumber]
@StartWith VARCHAR(50) = NULL,
@Idlist VARCHAR(max) = '0',
@CustomerId BIGINT = NULL,
@WorkOrderId BIGINT = NULL,
@WorkOrderTypeId INT = NULL,
@MasterCompanyId INT

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
		DECLARE @Sql NVARCHAR(MAX);	
		DECLARE @Count INT = 0;
		DECLARE @IsActive BIT = 1;

		IF(@Count = '0') 
		   BEGIN
		   SET @Count = '20';	
		END	

		IF(ISNULL(@StartWith, '') = '') 
		   BEGIN
		   SET @StartWith = '';	
		END	

		IF(ISNULL(@Idlist, '') = '') 
		   BEGIN
		   SET @Count = '0';	
		END	

		IF(@WorkOrderTypeId = 1) -- Customer Work Order
			BEGIN		
					DECLARE @CustomerModuleID INT; -- Module Enum
					DECLARE @RCWModuleID INT; -- Management Structure Module Enum
					
					SET @CustomerModuleID = 1
					SET @RCWModuleID = 1
					
					SELECT  RP.ItemMasterId AS ItemMasterId,
                            RP.ReferenceId AS ReferenceId, 
                            RP.PartType AS PartType 
					INTO #TempPMADER
					FROM dbo.ReceivingCustomerWork RCW
						JOIN dbo.ItemMaster IM ON RCW.ItemMasterId = IM.ItemMasterId
						JOIN dbo.RestrictedParts RP ON RCW.CustomerId = RP.ReferenceId
                    WHERE RCW.IsActive = 1 AND RCW.IsDeleted = 0 AND RP.ModuleId = @CustomerModuleID AND ISNULL(RCW.WorkOrderId, 0) = 0
                          AND RCW.CustomerId = @CustomerId AND RCW.ItemMasterId = RP.ItemMasterId AND RP.IsActive = 1 AND RP.IsDeleted = 0

					SELECT DISTINCT TOP 20 RCW.ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempPMADER WHERE #TempPMADER.PartType = 'PMA' AND #TempPMADER.ItemMasterId = IM.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempPMADER WHERE #TempPMADER.PartType = 'DER' AND #TempPMADER.ItemMasterId = IM.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        RCW.SerialNumber,
                        RCW.StockLineId,
                        RCW.ConditionId,
                        RCW.Reference,
						CONVERT(VARCHAR, RCW.ReceivedDate, 101)  AS  ReceivedDate,
                        RCW.ReceivingNumber,
                        RCW.ManagementStructureId,
                        RCW.CustReqDate,
                        RCW.Quantity,
                        RCW.WorkScopeId AS WorkOderScopeId,
						WS.WorkScopeCode AS WorkOrderScope,
						RCW.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						RCW.ACTailNum AS AircraftTailNumber					
					FROM dbo.ReceivingCustomerWork RCW WITH(NOLOCK) 
						JOIN dbo.WorkOrderManagementStructureDetails MSD WITH(NOLOCK) ON RCW.ReceivingCustomerWorkId = MSD.ReferenceID AND MSD.ModuleID = @RCWModuleID
						JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = RCW.StockLineId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = RCW.ItemMasterId
						JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = RCW.CustomerId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = RCW.ConditionId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = RCW.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
						LEFT JOIN dbo.WorkScope WS WITH(NOLOCK) ON WS.WorkScopeId = RCW.WorkScopeId
					WHERE RCW.IsActive = 1 AND RCW.IsDeleted = 0 AND ISNULL(RCW.WorkOrderId, 0) = 0 AND SL.CustomerId = @CustomerId AND ISNULL(SL.IsCustomerStock, 0) = 1 AND ISNULL(SL.IsParent, 0) = 1
						AND RCW.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%') 

					UNION 

					SELECT DISTINCT TOP 20 RCW.ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempPMADER WHERE #TempPMADER.PartType = 'PMA' AND #TempPMADER.ItemMasterId = IM.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempPMADER WHERE #TempPMADER.PartType = 'DER' AND #TempPMADER.ItemMasterId = IM.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        RCW.SerialNumber,
                        RCW.StockLineId,
                        RCW.ConditionId,
                        RCW.Reference,
						CONVERT(VARCHAR, RCW.ReceivedDate, 101)  AS  ReceivedDate,
                        RCW.ReceivingNumber,
                        RCW.ManagementStructureId,
                        RCW.CustReqDate,
                        RCW.Quantity,
                        RCW.WorkScopeId AS WorkOderScopeId,
						WS.WorkScopeCode AS WorkOrderScope,
						RCW.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						RCW.ACTailNum AS AircraftTailNumber						
					FROM dbo.ReceivingCustomerWork RCW WITH(NOLOCK) 
						JOIN dbo.WorkOrderManagementStructureDetails MSD WITH(NOLOCK) ON RCW.ReceivingCustomerWorkId = MSD.ReferenceID AND MSD.ModuleID = @RCWModuleID
						JOIN dbo.Stockline SL WITH(NOLOCK) ON SL.StockLineId = RCW.StockLineId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = RCW.ItemMasterId
						JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = RCW.CustomerId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = RCW.ConditionId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = RCW.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
						LEFT JOIN dbo.WorkScope WS WITH(NOLOCK) ON WS.WorkScopeId = RCW.WorkScopeId
					WHERE SL.StockLineId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@Idlist, ',')) AND ISNULL(SL.IsCustomerStock, 0) = 1 AND ISNULL(SL.IsParent, 0) = 1
					ORDER BY Label				
			END
			ELSE IF(@WorkOrderTypeId = 2 OR  @WorkOrderTypeId = 4) -- FOR INTERNAL AND SHOP SERVER WO TYPE
			BEGIN
					DECLARE @StocklineModuleID INT; 
					DECLARE @SLMSModuleID INT; 
					
					SET @StocklineModuleID = 53 -- STOCKLINE MODULE ENUM
					SET @SLMSModuleID = 2 -- MANAGEMENT STRUCTUER MODULE ENUM
					
					SELECT  RP.ItemMasterId AS ItemMasterId,
                            RP.ReferenceId AS ReferenceId, 
                            RP.PartType AS PartType 
					INTO #TempSLPMADER
					FROM dbo.StockLine SL
						JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
						JOIN dbo.RestrictedParts RP ON SL.CustomerId = RP.ReferenceId
                    WHERE SL.IsActive = 1 AND SL.IsDeleted = 0 AND RP.ModuleId = @StocklineModuleID AND ISNULL(SL.WorkOrderId, 0) = 0
                          AND SL.CustomerId = @CustomerId AND SL.ItemMasterId = RP.ItemMasterId AND RP.IsActive = 1 AND RP.IsDeleted = 0

					SELECT DISTINCT TOP 20  0 AS ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempSLPMADER WHERE #TempSLPMADER.PartType = 'PMA' AND #TempSLPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempSLPMADER WHERE #TempSLPMADER.PartType = 'DER' AND #TempSLPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        SL.SerialNumber,
                        SL.StockLineId,
                        SL.ConditionId,
                        ''  AS Reference,
						CONVERT(VARCHAR, SL.ReceivedDate, 101)  AS  ReceivedDate,
                        '' AS ReceivingNumber,
                        SL.ManagementStructureId,
                        GETUTCDATE() AS CustReqDate,
                        SL.Quantity,
                        0 AS WorkOderScopeId,
						'' AS WorkOrderScope,
						SL.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						SL.AircraftTailNumber AS AircraftTailNumber					
					FROM dbo.StockLine SL WITH(NOLOCK) 
						JOIN dbo.StocklineManagementStructureDetails MSD WITH(NOLOCK) ON SL.StockLineId = MSD.ReferenceID AND MSD.ModuleID = @SLMSModuleID
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = SL.ConditionId
						LEFT JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = SL.CustomerId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = SL.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
					WHERE SL.IsActive = 1 AND SL.IsDeleted = 0 AND ISNULL(SL.WorkOrderId, 0) = 0 AND ISNULL(SL.IsParent,0) = 1 AND ISNULL(SL.IsCustomerStock, 0) = 0 AND ISNULL(SL.QuantityAvailable, 0) > 0
						AND SL.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%')

					UNION

					SELECT  0 AS ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempSLPMADER WHERE #TempSLPMADER.PartType = 'PMA' AND #TempSLPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempSLPMADER WHERE #TempSLPMADER.PartType = 'DER' AND #TempSLPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        SL.SerialNumber,
                        SL.StockLineId,
                        SL.ConditionId,
                        ''  AS Reference,
						CONVERT(VARCHAR, SL.ReceivedDate, 101)  AS  ReceivedDate,
                        '' AS ReceivingNumber,
                        SL.ManagementStructureId,
                        GETUTCDATE() AS CustReqDate,
                        SL.Quantity,
                        0 AS WorkOderScopeId,
						'' AS WorkOrderScope,
						SL.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						SL.AircraftTailNumber AS AircraftTailNumber				
					FROM dbo.StockLine SL WITH(NOLOCK) 
						JOIN dbo.StocklineManagementStructureDetails MSD WITH(NOLOCK) ON SL.StockLineId = MSD.ReferenceID AND MSD.ModuleID = @SLMSModuleID
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = SL.ConditionId
						LEFT JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = SL.CustomerId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = SL.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
					WHERE SL.StockLineId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@Idlist, ',')) AND ISNULL(SL.IsParent,0) = 1 AND ISNULL(SL.IsCustomerStock, 0) = 0
					ORDER BY Label	
			END
			ELSE IF(@WorkOrderTypeId = 3)
			BEGIN
					DECLARE @TRStocklineModuleID INT; 
					DECLARE @TRSLMSModuleID INT; 
					
					SET @StocklineModuleID = 53 -- Stockline Module Enum
					SET @SLMSModuleID = 2 -- Management Structure Module Enum
					
					SELECT  RP.ItemMasterId AS ItemMasterId,
                            RP.ReferenceId AS ReferenceId, 
                            RP.PartType AS PartType 
					INTO #TempTRPMADER
					FROM dbo.StockLine SL
						JOIN dbo.ItemMaster IM ON SL.ItemMasterId = IM.ItemMasterId
						JOIN dbo.RestrictedParts RP ON SL.CustomerId = RP.ReferenceId
                    WHERE SL.IsActive = 1 AND SL.IsDeleted = 0 AND RP.ModuleId = @StocklineModuleID AND ISNULL(SL.WorkOrderId, 0) = 0
                          AND SL.CustomerId = @CustomerId AND SL.ItemMasterId = RP.ItemMasterId AND RP.IsActive = 1 AND RP.IsDeleted = 0

					SELECT DISTINCT TOP 20 
						0 AS ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempTRPMADER WHERE #TempTRPMADER.PartType = 'PMA' AND #TempTRPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempTRPMADER WHERE #TempTRPMADER.PartType = 'DER' AND #TempTRPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        SL.SerialNumber,
                        SL.StockLineId,
                        SL.ConditionId,
                        ''  AS Reference,
						CONVERT(VARCHAR, SL.ReceivedDate, 101)  AS  ReceivedDate,
                        '' AS ReceivingNumber,
                        SL.ManagementStructureId,
                        GETUTCDATE() AS CustReqDate,
                        SL.Quantity,
                        0 AS WorkOderScopeId,
						'' AS WorkOrderScope,
						SL.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						SL.AircraftTailNumber AS AircraftTailNumber						
					FROM dbo.StockLine SL WITH(NOLOCK) 
						JOIN dbo.StocklineManagementStructureDetails MSD WITH(NOLOCK) ON SL.StockLineId = MSD.ReferenceID AND MSD.ModuleID = @SLMSModuleID
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = SL.ConditionId
						LEFT JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = SL.CustomerId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = SL.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
					WHERE SL.IsActive = 1 AND SL.IsDeleted = 0 AND ISNULL(SL.WorkOrderId, 0) = 0 AND ISNULL(SL.IsParent,0) = 1 AND ISNULL(SL.QuantityAvailable, 0) > 0
						AND SL.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%')

					UNION

					SELECT 0 AS ReceivingCustomerWorkId,
						SL.ItemMasterId,
						IM.partnumber AS PartNumber,
						CASE WHEN (SELECT COUNT(1) FROM dbo.ItemMaster IMF WHERE IMF.MasterCompanyId = IM.MasterCompanyId AND IM.partnumber = IMF.partnumber) > 1 THEN IM.partnumber + '' + IM.ManufacturerName ELSE IM.partnumber END AS [Label],
						CASE WHEN (SELECT COUNT(1) FROM #TempTRPMADER WHERE #TempTRPMADER.PartType = 'PMA' AND #TempTRPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS PMA,
						CASE WHEN (SELECT COUNT(1) FROM #TempTRPMADER WHERE #TempTRPMADER.PartType = 'DER' AND #TempTRPMADER.ItemMasterId = SL.ItemMasterId) > 0 THEN 0 ELSE C.RestrictPMA END AS DER,
						IM.PartDescription,
                        IM.ManufacturerName,
						ISNULL(IM.RevisedPartId, 0) As RevisedPartId,
						ISNULL(IM.RevisedPart, '') As RevisedPartNo,
						CO.Description AS Condition,
                        sl.StockLineNumber,
                        SL.SerialNumber,
                        SL.StockLineId,
                        SL.ConditionId,
                        ''  AS Reference,
						CONVERT(VARCHAR, SL.ReceivedDate, 101)  AS  ReceivedDate,
                        '' AS ReceivingNumber,
                        SL.ManagementStructureId,
                        GETUTCDATE() AS CustReqDate,
                        SL.Quantity,
                        0 AS WorkOderScopeId,
						'' AS WorkOrderScope,
						SL.ManagementStructureId AS EntityStructureId,
						MSD.AllMSlevels,
						MSD.LastMSLevel,
						IG.[Description] AS ItemGroup,
						WF.WorkflowExpirationDate AS WorkflowExpirationDate,
						SL.AircraftTailNumber AS AircraftTailNumber					
					FROM dbo.StockLine SL WITH(NOLOCK) 
						JOIN dbo.StocklineManagementStructureDetails MSD WITH(NOLOCK) ON SL.StockLineId = MSD.ReferenceID AND MSD.ModuleID = @SLMSModuleID
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SL.ItemMasterId
						JOIN dbo.Condition CO WITH(NOLOCK) ON CO.ConditionId = SL.ConditionId
						LEFT JOIN dbo.Customer C WITH(NOLOCK) ON C.CustomerId = SL.CustomerId
						LEFT JOIN dbo.ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId = IG.ItemGroupId
						LEFT JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOWF.WorkOrderId = SL.WorkOrderId
						LEFT JOIN dbo.Workflow WF WITH(NOLOCK) ON WF.WorkflowId = WOWF.WorkflowId
					WHERE SL.StockLineId IN (SELECT DISTINCT Item FROM DBO.SPLITSTRING(@Idlist, ',')) AND ISNULL(SL.IsParent,0) = 1
					ORDER BY Label	
			END

	END TRY 
	BEGIN CATCH			  
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsWorkOrderPartNumber'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))  	
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH	
END