/*************************************************************           
 ** File:   [UpdateWorkOrderColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Details based in WO Id.    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    12/30/2020   Hemant Saliya		Created
	2    07/19/2021   Hemant Saliya		Added SP Call for WO Status Update
	3    10/16/2024   Moin Bloch		Updated RevisedPartDescription if not exists
	4    10/21/2024   Devendra Shekh	added Fields for WPN update
    5    14/Feb/2025  RAJESH GAMI		added PublicationNo in WO Part Number
    6    28/APR/2025  Vishal Suthar		added partnumber column to update from itemmaster
	7    30/APR/2025  Hemant Saliya		Added Revised PN, Revised Serial Number , Revised PN Desc
	8    27/MAY/2025  Abhishek Jirawla	Added WHERE condition in Publication CMM number update last step

-- EXEC [UpdateWorkOrderPartNumberColumnsWithId] 30
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdateWorkOrderPartNumberColumnsWithId]
@WorkOrderPartNumberId int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				DECLARE @MSID as bigint
				DECLARE @Level1 as varchar(200)
				DECLARE @Level2 as varchar(200)
				DECLARE @Level3 as varchar(200)
				DECLARE @Level4 as varchar(200)

				IF OBJECT_ID(N'tempdb..#WorkOrderPartMSDATA') IS NOT NULL
				BEGIN
					DROP TABLE #WorkOrderPartMSDATA 
				END

					CREATE TABLE #WorkOrderPartMSDATA
					(
					 MSID bigint,
					 Level1 varchar(200) NULL,
					 Level2 varchar(200) NULL,
					 Level3 varchar(200) NULL,
					 Level4 varchar(200) NULL 
					)

				IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
				BEGIN
				DROP TABLE #MSDATA 
				END
				CREATE TABLE #MSDATA
				(
					ID int IDENTITY, 
					MSID bigint 
				)
				INSERT INTO #MSDATA (MSID)
				  SELECT WPN.ManagementStructureId 				  
				FROM dbo.WorkOrderPartNumber WPN WITH(NOLOCK) 
				WHERE WPN.ID = @WorkOrderPartNumberId

				DECLARE @LoopID as int 
				SELECT  @LoopID = MAX(ID) FROM #MSDATA
				WHILE(@LoopID > 0)
				BEGIN
				SELECT @MSID = MSID FROM #MSDATA WHERE ID  = @LoopID

				EXEC dbo.GetMSNameandCode @MSID,
				 @Level1 = @Level1 OUTPUT,
				 @Level2 = @Level2 OUTPUT,
				 @Level3 = @Level3 OUTPUT,
				 @Level4 = @Level4 OUTPUT

				INSERT INTO #WorkOrderPartMSDATA
							(MSID, Level1,Level2,Level3,Level4)
					  SELECT @MSID,@Level1,@Level2,@Level3,@Level4
				SET @LoopID = @LoopID - 1;
				END 

				--SELECT * FROM #WorkOrderPartMSDATA

				UPDATE WPN SET 
					WPN.Level1 = WMS.Level1,
					WPN.Level2 = WMS.Level2,
					WPN.Level3 = WMS.Level3,
					WPN.Level4 = WMS.Level4,
					WPN.[PartNumber] = IM.[partnumber],
					WPN.[PartDescription] = IM.[PartDescription],
					WPN.[WorkOrderStatus] = WOS.[Description],
					WPN.[Priority] = PR.[Description],
					WPN.[WorkOrderStage] = WOSG.[Code] + '-' + WOSG.[Stage],
					WPN.[ManufacturerName] = IM.[ManufacturerName],
					WPN.[TechName] = UPPER(EMP.FirstName + ' ' + EMP.LastName),
					WPN.[EmployeeStation] = UPPER(EMPS.StationName),
					WPN.[RevisedItemmasterid] = CASE WHEN WPN.[RevisedItemmasterid] > 0 THEN WPN.[RevisedItemmasterid] ELSE WPN.ItemMasterId END
				FROM [dbo].WorkOrderPartNumber WPN WITH(NOLOCK) 
				LEFT JOIN #WorkOrderPartMSDATA WMS ON WMS.MSID = WPN.ManagementStructureId
				LEFT JOIN [dbo].[WorkOrderStatus] WOS WITH(NOLOCK) ON WOS.Id = WPN.WorkOrderStatusId  
				LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId         
				LEFT JOIN [dbo].[Priority] PR WITH(NOLOCK) ON WPN.WorkOrderPriorityId = PR.PriorityId  
				LEFT JOIN [dbo].[WorkOrderStage] WOSG WITH(NOLOCK) ON WPN.WorkOrderStageId = WOSG.WorkOrderStageId
				LEFT JOIN [dbo].[Employee] EMP WITH(NOLOCK) ON EMP.EmployeeId = WPN.TechnicianId  
				LEFT JOIN [dbo].[EmployeeStation] EMPS WITH(NOLOCK) ON WPN.TechStationId = EMPS.EmployeeStationId
				WHERE WPN.ID = @WorkOrderPartNumberId

				IF EXISTS(SELECT ID FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND [RevisedPartDescription] IS NULL)
				BEGIN					
					UPDATE WPN SET 						
						WPN.[RevisedPartDescription] = IM.[PartDescription]				
					FROM [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) 
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WPN.[RevisedItemmasterid]
					WHERE WPN.[ID] = @WorkOrderPartNumberId
				END		

				IF EXISTS(SELECT ID FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND ISNULL([RevisedPartNumber] ,'') = '')
				BEGIN					
					UPDATE WPN SET 
						WPN.[RevisedPartNumber] = IM.[PartNumber],	
						WPN.[RevisedPartDescription] = IM.[PartDescription]
					FROM [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) 
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WPN.[RevisedItemmasterid]
					WHERE WPN.[ID] = @WorkOrderPartNumberId
				END

				IF EXISTS(SELECT ID FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND ISNULL([CurrentSerialNumber], '') = '')
				BEGIN					
					UPDATE WPN SET 
						WPN.[CurrentSerialNumber] = SL.[SerialNumber]								
					FROM [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) 
					LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = WPN.[StockLineId]
					WHERE WPN.[ID] = @WorkOrderPartNumberId
				END

				IF EXISTS(SELECT ID FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNumberId AND ISNULL([RevisedSerialNumber], '') = '')
				BEGIN					
					UPDATE WPN SET 
						WPN.[RevisedSerialNumber] = CASE WHEN ISNULL(WPN.CurrentSerialNumber, '') = '' THEN SL.[SerialNumber] ELSE WPN.CurrentSerialNumber END								
					FROM [dbo].[WorkOrderPartNumber] WPN WITH(NOLOCK) 
					LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON SL.[StockLineId] = WPN.[StockLineId]
					WHERE WPN.[ID] = @WorkOrderPartNumberId
				END
								
				UPDATE WOPN
					SET WOPN.PublicationNo = (
						SELECT STRING_AGG(P.PublicationId, ',') 
						FROM Publication P
						WHERE 
							ISNULL(WOPN.CMMIds, '') <> '' AND 
							(WOPN.CMMIds = CAST(P.PublicationRecordId AS VARCHAR) OR
							 ',' + WOPN.CMMIds + ',' LIKE '%,' + CAST(P.PublicationRecordId AS VARCHAR) + ',%')
					)
					FROM [dbo].[WorkOrderPartNumber] WOPN WITH(NOLOCK)
					WHERE WOPN.[ID] = @WorkOrderPartNumberId;

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderPartNumberColumnsWithId' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderPartNumberId, '') AS VARCHAR(100))  
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