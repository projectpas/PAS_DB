
/*************************************************************           
 ** File:   [RPT_GetCommonSubWorkOrderFormTypePrintView]       
 ** Author: RAJESH GAMI
 ** Description: This stored procedure is used retrieve Common Sub Work Order Form Type (Task) for SSRS report
 ** Purpose:         
 ** Date:   03 APR 2025

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date           Author		         Change Description            
 ** --   ----------    -----------		--------------------------------          
    1    03 APR 2025   RAJESH GAMI			Created    
-- EXEC  [dbo].[RPT_GetCommonSubWorkOrderFormTypePrintView] 4769
**************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetCommonSubWorkOrderFormTypePrintView]
	@SubWorkorderId BIGINT = 0,
	@WorkorderId BIGINT = 0,
	@SubWOPartNoId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				;WITH CTE AS (
					SELECT 
						ISNULL(WOT.SubWorkOrderTaskId, 0) AS WorkOrderTaskId,
						ISNULL(WOT.WorkOrderId, 0) AS WorkOrderId,
						ISNULL(WOT.SubWOPartNoId, 0) AS WorkOrderPartNumberId,
						ISNULL(WOT.TaskId, 0) AS TaskId,
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
						ISNULL(WOTI.PrintInWOQ, 0) AS PrintInWOQ
					FROM dbo.SubWorkOrderTask WOT WITH (NOLOCK)
					INNER JOIN dbo.SubWorkOrderTaskDetails WOTD WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOTD.SubWorkOrderTaskId
					LEFT JOIN dbo.SubWorkOrderTaskInstruction WOTI WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = WOTI.SubWorkOrderTaskId AND ISNULL(WOTI.PrintInWO,0) = 1
					WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.SubWorkOrderId = @SubWorkorderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND ISNULL(WOTD.PrintInWO,0) = 1 AND ISNULL(WOT.SubWOPartNoId,0) = @SubWOPartNoId
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
					WorkOrderTaskId,
					WorkOrderId,
					WorkOrderPartNumberId,
					TaskId,
					SequenceNumber,
					OpenDate,
					OpenBy,
					IsIncludeInPrint,
					HasInstruction,
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
					CreatedBy,
					CreatedDate,
					UpdatedBy,
					UpdatedDate,
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
					PrintInWO,
					PrintInWOQ,
					SrNo
				FROM RecursiveCTE
				ORDER BY SequenceNumber;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonSubWorkOrderFormTypePrintView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END