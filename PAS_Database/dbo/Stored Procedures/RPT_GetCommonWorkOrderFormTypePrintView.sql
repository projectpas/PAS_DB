/*************************************************************           
 ** File:   [RPT_GetCommonWorkOrderFormTypePrintView]       
 ** Author: RAJESH GAMI
 ** Description: This stored procedure is used retrieve Common Work Order Form Type (Task) for SSRS report
 ** Purpose:         
 ** Date:   9 JAN 2025

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		         Change Description            
 ** --   ----------   -----------		--------------------------------          
    1    9 JAN 2025   RAJESH GAMI			Created    
    2    16 JAN 2025  RAJESH GAMI			Updated to print only Instruction which has PrintInWO is enabled 
	3    21 JAN 2025  RAJESH GAMI			Updated to print only Task which has PrintInWO is enabled
	4    21 JAN 2025  RAJESH GAMI			Added workOrderPartNoId in the parameter and functional
	5    03-MAR-2025   RAJESH GAMI			Sequence Number Change
	6	 29-Aug-2025   Moin Bloch		    Added IsPrintAdmin flag
	7	 20-JAN-2026   Rajesh Gami		Fixed the sequence number issue 
	8	 11-SEP-2026   SUMIT KUMAR	Return one row per task instruction image for print (PN-17814)
-- EXEC  [dbo].[RPT_GetCommonWorkOrderFormTypePrintView] 4769
**************************************************************/
CREATE       PROCEDURE [dbo].[RPT_GetCommonWorkOrderFormTypePrintView]
	@WorkorderId bigint = 0,
	@workOrderPartNoId bigint = 0,
	@ApiBaseUrl VARCHAR(500) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				-- [PN-17814] Base URL for task instruction images; trailing slash removed
				DECLARE @ImageBaseUrl VARCHAR(500) = LTRIM(RTRIM(ISNULL(@ApiBaseUrl, '')));
				IF RIGHT(@ImageBaseUrl, 1) = '/'
					SET @ImageBaseUrl = LEFT(@ImageBaseUrl, LEN(@ImageBaseUrl) - 1);
				;WITH CTE AS (
					SELECT 
						ISNULL(WOT.WorkOrderTaskId, 0) AS WorkOrderTaskId,
						ISNULL(WOT.WorkOrderId, 0) AS WorkOrderId,
						ISNULL(WOT.WorkOrderPartNumberId, 0) AS WorkOrderPartNumberId,
						ISNULL(WOT.WorkFlowWorkOrderId, 0) AS WorkFlowWorkOrderId,
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
						ISNULL(WOTD.IsPrintTechnician,0) IsPrintTechnician,
						ISNULL(WOTD.IsPrintAdmin,0) IsPrintAdmin,
						TRY_CAST(WOT.SequenceNumber AS INT) AS SequenceNumberSort
					FROM dbo.WorkOrderTask WOT WITH (NOLOCK)
					INNER JOIN dbo.WorkOrderTaskDetails WOTD WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTD.WorkOrderTaskId
					LEFT JOIN dbo.WorkOrderTaskInstruction WOTI WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOTI.WorkOrderTaskId AND ISNULL(WOTI.PrintInWO,0) = 1
					WHERE WOT.WorkOrderId = @WorkOrderId AND WOT.IsActive = 1 AND WOT.IsDeleted = 0 AND ISNULL(WOTD.PrintInWO,0) = 1 AND ISNULL(WOT.WorkOrderPartNumberId,0) = @workOrderPartNoId
				),
				--RecursiveCTE AS (				
				--	--SELECT 
				--	--	c.*,
				--	--	CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--	--FROM CTE c
				--	--WHERE c.ParentId = 0
				--	--UNION ALL
				
				--	--SELECT 
				--	--	c.*,
				--	--	CAST(r.SrNo + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS SrNo
				--	--FROM CTE c
				--	--INNER JOIN RecursiveCTE r ON c.ParentId = r.WorkOrderTaskInstructionId
				--	--SELECT 
				--	--	c.*
				--	--	,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--	--	--,CAST(c.SequenceNumber AS NVARCHAR(MAX)) AS SrNo
				--	--FROM CTE c
				--	--WHERE c.ParentId = 0
				--	--UNION ALL
				
				--	--SELECT 
				--	--	c.*,
				--	--	CAST(r.SrNo + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS SrNo
				--	--FROM CTE c
				--	--INNER JOIN RecursiveCTE r ON c.ParentId = r.WorkOrderTaskInstructionId

				--	SELECT 
				--		c.*
				--		--,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--		,CAST(c.SequenceNumber AS NVARCHAR(MAX)) + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.SequenceNumber ORDER BY c.ChildSequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--		 --,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--		 --,CAST(ROW_NUMBER() OVER (ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS SrNo
				--	FROM CTE c
				--	WHERE c.ParentId = 0
				--	UNION ALL
				
				--	SELECT 
				--		c.*,
				--		--CAST(r.SrNo + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS SrNo
				--		--,CAST(c.SequenceNumber AS NVARCHAR(MAX)) AS Seq
				--		 CAST(r.SrNo + '.' + 
				--			 --CAST(ROW_NUMBER() OVER (PARTITION BY c.ParentId ORDER BY c.SequenceNumber) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)
				--			 CAST(c.ChildSequenceNumber AS NVARCHAR(MAX)) AS NVARCHAR(MAX)
				--			 )
				--			 AS SrNo
				--	FROM CTE c
				--	INNER JOIN RecursiveCTE r ON c.ParentId = r.WorkOrderTaskInstructionId
				--)
				RecursiveCTE AS (				
					SELECT 
						c.*
						,CAST(c.SequenceNumberSort AS NVARCHAR(MAX)) + '.' + CAST(ROW_NUMBER() OVER (PARTITION BY c.SequenceNumberSort ORDER BY c.WorkOrderTaskInstructionId) AS NVARCHAR(MAX)) AS SrNo
					FROM CTE c
					WHERE c.ParentId = 0
					UNION ALL
				
					SELECT 
						c.*,
						CAST(r.SrNo + '.' + 
						CAST(ROW_NUMBER() OVER (
							PARTITION BY c.WorkOrderTaskInstructionId 
							ORDER BY c.WorkOrderTaskInstructionId ASC
						) AS NVARCHAR(MAX)) AS NVARCHAR(MAX)) AS SrNo
					FROM CTE c
					INNER JOIN RecursiveCTE r ON c.ParentId = r.WorkOrderTaskInstructionId
				)
				SELECT 
					WorkOrderTaskId,
					WorkOrderId,
					WorkOrderPartNumberId,
					WorkFlowWorkOrderId,
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
					IsPrintTechnician,
					IsPrintAdmin,
				SrNo,
				SequenceNumberSort
			INTO #TMPTaskInstructionData
			FROM RecursiveCTE;

			-- [PN-17814] One row per task instruction image so the report can repeat an image
			-- block under each instruction. Instructions with no images still return one row.
			SELECT
				F.WorkOrderTaskId,
				F.WorkOrderId,
				F.WorkOrderPartNumberId,
				F.WorkFlowWorkOrderId,
				F.TaskId,
				F.SequenceNumber,
				F.OpenDate,
				F.OpenBy,
				F.IsIncludeInPrint,
				F.HasInstruction,
				F.TaskName,
				F.TechId,
				F.TechName,
				F.TechUpdatedDate,
				F.InspectorId,
				F.InspectorName,
				F.InspectorUpdatedDate,
				F.Descrepancy,
				F.Resolution,
				F.MasterCompanyId,
				F.CreatedBy,
				F.CreatedDate,
				F.UpdatedBy,
				F.UpdatedDate,
				F.WorkOrderTaskInstructionId,
				F.ParentId,
				F.IsParent,
				F.InstructionTitle,
				F.ChildSequenceNumber,
				F.InstructionDetails,
				F.ChildTechId,
				F.ChildTechName,
				F.ChildTechUpdatedDate,
				F.ChildInspectorId,
				F.ChildInspectorName,
				F.ChildInspectorUpdatedDate,
				F.PrintInWO,
				F.PrintInWOQ,
				F.IsPrintTechnician,
				F.IsPrintAdmin,
				F.SrNo,
				ISNULL(IMG.WorkOrderTaskInstructionImageId, 0) AS WorkOrderTaskInstructionImageId,
				ISNULL(IMG.[FileName], '') AS InstructionImageFileName,
				-- NULL (not '') when there is no image: SSRS rejects an empty string as ImageData
				CASE
					WHEN IMG.WorkOrderTaskInstructionImageId IS NULL THEN NULL
					WHEN @ImageBaseUrl = '' THEN NULL
					WHEN ISNULL(IMG.[Link], '') = '' THEN NULL
					ELSE @ImageBaseUrl + '/api/FileUpload/viewattachedfile?filePath='
						+ REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(IMG.[Link], '%', '%25'), ' ', '%20'), '#', '%23'), '&', '%26'), '+', '%2B')
				END AS InstructionImageUrl
			FROM #TMPTaskInstructionData F
			LEFT JOIN [dbo].[WorkOrderTaskInstructionImage] IMG WITH (NOLOCK)
				ON IMG.WorkOrderTaskInstructionId = F.WorkOrderTaskInstructionId
				AND IMG.MasterCompanyId = F.MasterCompanyId
				AND IMG.IsActive = 1
				AND IMG.IsDeleted = 0
			ORDER BY F.SequenceNumberSort, F.WorkOrderTaskInstructionId, IMG.WorkOrderTaskInstructionImageId;
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonWorkOrderFormTypePrintView' 
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