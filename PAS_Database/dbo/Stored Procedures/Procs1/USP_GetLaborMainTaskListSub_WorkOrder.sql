-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetLaborMainTaskListSub_WorkOrder]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2023   Subhash Saliya		Created
  	2    18-Apr-2025  RAJESH GAMI			Modified to add logic for the get TASK based on the WorkOrderFormTypeId condition(Task base or Teardown WO).	
     
-- EXEC [USP_GetLaborMainTaskListSub_WorkOrder] 692,682
**************************************************************/

CREATE     PROCEDURE [dbo].[USP_GetLaborMainTaskListSub_WorkOrder]
 @subWOPartNoId bigint ,
 @subWorkOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

				declare @DataEnteredBy bigint =0
				DECLARE @Traveler_setupid AS BIGINT = 0;
				DECLARE @WorkOrderPartId AS BIGINT = 0;
				DECLARE @WorkScopeId AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT = 0;
				declare @IstravelerTask bit =0
			    declare @highestSequence bigint =0,@IsWorkOrderFormType BIT =0,@workorderId bigint=0;
                
				SET @WorkOrderPartId=@subWOPartNoId
                select top 1 @workorderId = WorkorderId,@ItemMasterId=ItemMasterId,@WorkScopeId=SubWorkOrderScopeId,@IstravelerTask=IsTraveler from DBo.SubWorkOrderPartNumber WITH(NOLOCK)  where SubWOPartNoId=@WorkOrderPartId
				IF(@workorderId > 0)
				BEGIN
					SELECT @IsWorkOrderFormType = ISNULL(WorkOrderFormTypeId,0) FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
				END

			     IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0
				 
					select  top 1 @highestSequence= Sequence from Traveler_Setup_Task    where  Traveler_setupid =@Traveler_setupid order by Sequence desc
				 END
				 else IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0

					select  top 1 @highestSequence= Sequence from Traveler_Setup_Task    where  Traveler_setupid =@Traveler_setupid order by Sequence desc
				 END

				  IF OBJECT_ID(N'tempdb..#TMPFinalData') IS NOT NULL    
					BEGIN    
						DROP TABLE #TMPFinalData
					END
					PRINT @IsWorkOrderFormType
				 IF(@IsWorkOrderFormType = 1)
				 BEGIN
					;WITH CTE AS (
					SELECT DISTINCT
						ISNULL(WOT.SubWorkOrderTaskId, 0) AS WorkOrderTaskId,
						ISNULL(WOT.SubWorkOrderId, 0) AS SubWorkOrderId,
						ISNULL(WOT.WorkOrderId, 0) AS WorkOrderId,
						ISNULL(WOT.SubWOPartNoId, 0) AS WorkOrderPartNumberId,
						ISNULL(WOT.SequenceNumber, 0) AS SequenceNumber,
						WOT.OpenDate AS OpenDate,
						ISNULL(WOT.OpenBy, '') AS OpenBy,
						ISNULL(WOT.IsIncludeInPrint, 0) AS IsIncludeInPrint,
						ISNULL(WOT.HasInstruction, 0) AS HasInstruction,
						ISNULL(WOT.TaskName, '') AS TaskName,
						ISNULL(WOTD.TechId, 0) AS TechId,
						ISNULL(WOTD.TechName, '') AS TechName,
						WOTD.TechUpdatedDate AS TechUpdatedDate,
						ISNULL(WOTD.InspectorId, 0) AS InspectorId,
						ISNULL(WOTD.InspectorName, '') AS InspectorName,
						WOTD.InspectorUpdatedDate AS InspectorUpdatedDate,
						ISNULL(WOTD.Descrepancy, '') AS Descrepancy,
						ISNULL(WOTD.Resolution, '') AS Resolution,
						ISNULL(WOT.MasterCompanyId, 0) AS MasterCompanyId,
						ISNULL(WOT.CreatedBy, '') AS CreatedBy,
						ISNULL(WOT.CreatedDate, '') AS CreatedDate,
						ISNULL(WOT.UpdatedBy, '') AS UpdatedBy,
						ISNULL(WOT.UpdatedDate, '') AS UpdatedDate,
						WOTI.SubWorkOrderTaskInstructionId WorkOrderTaskInstructionId,
						ISNULL(WOTI.ParentId, 0) AS ParentId,
						ISNULL(WOTI.IsParent, 0) AS IsParent,
						ISNULL(WOTI.InstructionTitle, '') AS InstructionTitle,
						ISNULL(WOTI.SequenceNumber, 0) AS ChildSequenceNumber,
						ISNULL(WOTI.InstructionDetails, '') AS InstructionDetails,
						ISNULL(WOTI.TechId, 0) AS ChildTechId,
						ISNULL(WOTI.TechName, '') AS ChildTechName,
						WOTI.TechUpdatedDate AS ChildTechUpdatedDate,
						ISNULL(WOTI.InspectorId, 0) AS ChildInspectorId,
						ISNULL(WOTI.InspectorName, '') AS ChildInspectorName,
						WOTI.InspectorUpdatedDate AS ChildInspectorUpdatedDate,
						ISNULL(WOTI.PrintInWO, 0) AS PrintInWO,
						ISNULL(WOTI.PrintInWOQ, 0) AS PrintInWOQ,
						0 as WorkOrderLaborId,
						wl.[TaskId],
						ISNULL(WOTD.IsPrintInspector,0) IsPrintInspector,
						ISNULL(WOTD.IsPrintTechnician,0) IsPrintTechnician
					FROM [dbo].[SubWorkOrderLabor] wl  WITH(NOLOCK) 
					Inner Join SubWorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.SubWorkOrderLaborHeaderId=wl.SubWorkOrderLaborHeaderId
					INNER JOIN dbo.SubWorkOrderTask WOT WITH (NOLOCK) on wl.TaskId = WOT.SubWorkOrderTaskId
					INNER JOIN dbo.SubWorkOrderTaskDetails WOTD WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOTD.SubWorkOrderTaskId
					LEFT JOIN dbo.SubWorkOrderTaskInstruction WOTI WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOTI.SubWorkOrderTaskId 
					WHERE wlh.SubWorkOrderId =@subWorkOrderId AND ISNULL(WOT.IsActive,0) = 1 AND ISNULL(WOT.IsDeleted,0) = 0 
				),
				RecursiveCTE AS (				
					SELECT 
						c.*
						,CAST(c.SequenceNumber AS NVARCHAR(MAX)) + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.SequenceNumber ORDER BY c.ChildSequenceNumber) AS NVARCHAR(MAX)) AS SrNo
					FROM CTE c
					WHERE c.ParentId = 0
					UNION ALL
				
					SELECT 
						c.*,
						 CAST(r.SrNo + '.' + 
							 CAST(c.ChildSequenceNumber AS NVARCHAR(MAX)) AS NVARCHAR(MAX)
							 )
							 AS SrNo
					FROM CTE c
					INNER JOIN RecursiveCTE r ON c.ParentId = r.WorkOrderTaskInstructionId
				)
				SELECT 
					TaskId,
					'' as TaskInstruction,
					'' as Task,
					WorkOrderLaborId,
					0 as [Sequence],
					0 as HighestSequence,
					WorkOrderTaskId ,
					WorkOrderId,
					SubWorkOrderId,
					SequenceNumber,
					TaskName,
					TechId,
					TechName,
					TechUpdatedDate,
					InspectorId,
					InspectorName,
					InspectorUpdatedDate,
					Descrepancy,
					Resolution,
					MasterCompanyId,
					ISNULL(WorkOrderTaskInstructionId,0)WorkOrderTaskInstructionId,
					ParentId,
					IsParent,
					InstructionTitle,
					ChildSequenceNumber,
					REPLACE(REPLACE(ISNULL(InstructionDetails,''), '<p>', ''),'</p>','<br />') as InstructionDetails,
					ChildTechId,
					ChildTechName,
					ChildTechUpdatedDate,
					ChildInspectorId,
					ChildInspectorName,
					ChildInspectorUpdatedDate,
					SrNo,
					1 as IsWorkOrderFormType,
					IsIncludeInPrint,
					IsPrintInspector,IsPrintTechnician
					 INTO #TMPFinalData 
				FROM RecursiveCTE
				ORDER BY SequenceNumber;
					SELECT * FROM #TMPFinalData ORDER BY SequenceNumber ASC
				 END
				 ELSE
				 BEGIN
					SELECT 
					wl.[TaskId]
					,Max([TaskInstruction]) as TaskInstruction
					,Max(UPPER(T.Description)) as Task
					,Max(SubWorkOrderLaborId) as WorkOrderLaborId
					,Max(Isnull(TTS.Sequence,9999)) as Sequence,
					 Max(@highestSequence) as HighestSequence,
					0 as  WorkOrderTaskId ,
					0 as  WorkOrderId,
					0 as  SubWorkOrderId,
					0 as  SequenceNumber,
					'' as TaskName,
					0 as  TechId,
					'' as TechName,
					'' AS TechUpdatedDate,
					0 AS InspectorId,
					'' AS InspectorName,
					'' AS InspectorUpdatedDate,
					'' AS Descrepancy,
					'' AS Resolution,
					0 AS MasterCompanyId,
					0 AS WorkOrderTaskInstructionId,
					0 AS ParentId,
					0 AS IsParent,
					'' AS InstructionTitle,
					0 AS ChildSequenceNumber,
					'' as InstructionDetails,
					0 AS ChildTechId,
					'' AS ChildTechName,
					'' AS ChildTechUpdatedDate,
					0 AS ChildInspectorId,
					'' AS ChildInspectorName,
					'' AS ChildInspectorUpdatedDate,
					0 AS SrNo,
					0 as IsWorkOrderFormType,
					0 as IsIncludeInPrint,
					CASE WHEN MAX(CAST(ISNULL(T.IsPrintInspector,0) AS INT)) = 1 THEN 1 ELSE 0 END IsPrintInspector,
					CASE WHEN MAX(CAST(ISNULL(T.IsPrintTechnician,0) AS INT)) = 1 THEN 1 ELSE 0 END IsPrintTechnician
					FROM [dbo].[SubWorkOrderLabor] wl  WITH(NOLOCK) 
					Inner Join DBO.SubWorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.SubWorkOrderLaborHeaderId=wl.SubWorkOrderLaborHeaderId
					Left Join DBO.Task T WITH(NOLOCK) on T.TaskId= wl.TaskId
					Left Join DBO.Traveler_Setup_Task TTS WITH(NOLOCK) on TTS.TaskId= wl.TaskId and Traveler_SetupId= @Traveler_setupid
				    where wl.IsDeleted=0 and wlh.SubWOPartNoId=@WorkOrderPartId and wlh.SubWorkOrderId =@subWorkOrderId group by  wl.[TaskId] order by Sequence asc
				 END				
                

                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLaborMainTaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END