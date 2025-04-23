/*************************************************************           
 ** File:   [USP_GetLaborTaskList]           
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
    1    01/03/2023    Subhash Saliya			Created
	2    02/21/2023	   Hemant Saliya			Updaetd to Upper Case
  	3    21-JAN-2025   RAJESH GAMI			    Modified to add logic for the get TASK based on the WorkOrderFormTypeId condition.
	4    27-JAN-2025   RAJESH GAMI			    remove the condition PrintInWO for the WorkOrderFormType, Need to display all the task and information..
	5    11-FEB-2025   RAJESH GAMI			    implemented IsPrintInspector IsPrintTechnician in traver print
	6    03-MAR-2025   RAJESH GAMI			    Sequence Number Change
-- EXEC [USP_GetLaborMainTaskList] 692,682
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_GetLaborMainTaskList]
 @WorkFlowWorkOrderId bigint,
 @WorkOrderId bigint
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
			    declare @highestSequence bigint =0, @IsWorkOrderFormType BIT =0;
                
				select top 1 @WorkOrderPartId=WorkOrderPartNoId from WorkOrderWorkFlow  where WorkFlowWorkOrderId=@WorkFlowWorkOrderId
                select top 1 @ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId,@IstravelerTask=IsTraveler from WorkOrderPartNumber  where ID=@WorkOrderPartId
				SELECT @IsWorkOrderFormType = ISNULL(WorkOrderFormTypeId,0) FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
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

				 IF(@IsWorkOrderFormType = 1)
				 BEGIN
					;WITH CTE AS (
					SELECT DISTINCT
						ISNULL(WOT.WorkOrderTaskId, 0) AS WorkOrderTaskId,
						ISNULL(WOT.WorkOrderId, 0) AS WorkOrderId,
						ISNULL(WOT.WorkOrderPartNumberId, 0) AS WorkOrderPartNumberId,
						ISNULL(WOT.WorkFlowWorkOrderId, 0) AS WorkFlowWorkOrderId,
						--ISNULL(WOT.TaskId, 0) AS TaskId,
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
						WOTI.WorkOrderTaskInstructionId,
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
					FROM [dbo].[WorkOrderLabor] wl  WITH(NOLOCK) 
					Inner Join WorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.WorkOrderLaborHeaderId=wl.WorkOrderLaborHeaderId
					INNER JOIN dbo.WorkOrderTask WOT WITH (NOLOCK) on wl.TaskId = WOT.WorkOrderTaskId
					INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
					LEFT JOIN dbo.WorkOrderTaskInstruction WOTI WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId -- --AND ISNULL(WOTI.PrintInWO,0) = 1
					WHERE wlh.WorkFlowWorkOrderId=@WorkFlowWorkOrderId and wlh.WorkOrderId =@WorkOrderId  AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 --AND ISNULL(WOTD.PrintInWO,0) = 1
				),
				RecursiveCTE AS (				
					SELECT 
						c.*
						--,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
						,CAST(c.SequenceNumber AS NVARCHAR(MAX)) + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.SequenceNumber ORDER BY c.ChildSequenceNumber) AS NVARCHAR(MAX)) AS SrNo
						 --,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
						 --,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
					FROM CTE c
					WHERE c.ParentId = 0
					UNION ALL
				
					SELECT 
						c.*,
						--CAST(r.SrNo + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS SrNo
						--,CAST(c.SequenceNumber AS NVARCHAR(MAX)) AS Seq
						 CAST(r.SrNo + '.' + 
							 --CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)
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
					SELECT * FROM #TMPFinalData ORDER BY SequenceNumber,SrNo ASC
				 END
				 ELSE
				 BEGIN
					SELECT 
					wl.[TaskId]
					,Max([TaskInstruction]) as TaskInstruction
					,Max(UPPER(T.Description)) as Task
					,Max(WorkOrderLaborId) as WorkOrderLaborId
					,Max(Isnull(TTS.Sequence,9999)) as Sequence,
					 Max(@highestSequence) as HighestSequence,
					0 as  WorkOrderTaskId ,
					0 as  WorkOrderId,
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
					FROM [dbo].[WorkOrderLabor] wl  WITH(NOLOCK) 
					Inner Join WorkOrderLaborHeader wlh WITH(NOLOCK)  on wlh.WorkOrderLaborHeaderId=wl.WorkOrderLaborHeaderId
					Left Join Task T WITH(NOLOCK) on T.TaskId= wl.TaskId
					Left Join Traveler_Setup_Task TTS WITH(NOLOCK) on TTS.TaskId= wl.TaskId and Traveler_SetupId= @Traveler_setupid
					where wl.IsDeleted=0 and wlh.WorkFlowWorkOrderId=@WorkFlowWorkOrderId and wlh.WorkOrderId =@WorkOrderId group by  wl.[TaskId] order by Sequence asc
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
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