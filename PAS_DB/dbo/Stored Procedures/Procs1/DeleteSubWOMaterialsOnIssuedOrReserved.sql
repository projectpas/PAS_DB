/*************************************************************   
-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <07-11-2023>
-- Description:	<Delete Sub WO Materials & its Stockline if not issued/ reserved & no WO Provision>
-- =============================================
**************************************************************

** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    07-11-2023		Ayesha Sultana		Created - Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision
** 2    07-11-2023		Hemnat Saliya		Updated - Added Kit Delete option
** 3    16/10/2024      RAJESH GAMI         Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials
** 4    29/10/2024      RAJESH GAMI         Un Mapped WO if there is no other material link with the same workorder in the Same PO (Updated)
** 5    13-02-2025		Hemnat Saliya		Updated - Re_calculate MPN Cost

EXEC DeleteSubWOMaterialsOnIssuedOrReserved 91
**************************************************************/ 

CREATE    PROCEDURE [dbo].[DeleteSubWOMaterialsOnIssuedOrReserved]
	@SubWOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
			DECLARE @SubWorkOrderId BIGINT = 0;
			DECLARE @PoID BIGINT = 0, @LooPId INT = 1, @TotalCount INT = 0
			IF OBJECT_ID(N'tempdb..##TempSubWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempSubWOtbl
				END
			IF OBJECT_ID(N'tempdb..##TempPOtbl') IS NOT NULL
			BEGIN
				DROP TABLE #TempPOtbl
			END
			CREATE TABLE #TempPOtbl(Id [int] IDENTITY(1,1),POID BIGINT NULL)

			CREATE TABLE #TempSubWOtbl(SubWorkOrderMaterialsId BIGINT, IsKit BIT)

			INSERT INTO #TempSubWOtbl (SubWorkOrderMaterialsId, IsKit)
			SELECT DISTINCT SWOM.SubWorkOrderMaterialsId, 0
			FROM dbo.SubWorkOrderMaterials SWOM WITH(NOLOCK)
			WHERE SWOM.SubWOPartNoId = @SubWOPartNoId AND (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0)) = 0 

			INSERT INTO #TempSubWOtbl (SubWorkOrderMaterialsId, IsKit)
			SELECT DISTINCT SWOM.SubWorkOrderMaterialsKitId, 1
			FROM dbo.SubWorkOrderMaterialsKit SWOM WITH(NOLOCK)
			WHERE SWOM.SubWOPartNoId = @SubWOPartNoId AND (ISNULL(SWOM.QuantityReserved, 0) + ISNULL(SWOM.QuantityIssued, 0)) = 0 

			SET @SubWorkOrderId = (SELECT TOP 1 SubWorkOrderId FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = (SELECT top 1 SubWorkOrderMaterialsId FROM #TempSubWOtbl))
			INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) WHERE SubWorkOrderMaterialsId IN (SELECT SubWorkOrderMaterialsId FROM  #TempSubWOtbl) AND ISNULL(POId,0) > 0
			INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK) WHERE SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsId FROM  #TempSubWOtbl) AND ISNULL(POId,0) > 0

			DELETE SWOMS FROM dbo.SubWorkOrderMaterialStockLine SWOMS JOIN #TempSubWOtbl tmpWOM ON SWOMS.SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId AND ISNULL(tmpWOM.IsKit, 0) = 0
			DELETE SWOM FROM dbo.SubWorkOrderMaterials SWOM JOIN #TempSubWOtbl tmpWOM ON SWOM.SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId AND ISNULL(tmpWOM.IsKit, 0) = 0;

			DELETE SWOMS FROM dbo.SubWorkOrderMaterialStockLineKit SWOMS JOIN #TempSubWOtbl tmpWOM ON SWOMS.SubWorkOrderMaterialsKitId = tmpWOM.SubWorkOrderMaterialsId AND ISNULL(tmpWOM.IsKit, 0) = 1
			DELETE SWOM FROM dbo.SubWorkOrderMaterialsKit SWOM JOIN #TempSubWOtbl tmpWOM ON SWOM.SubWorkOrderMaterialsKitId = tmpWOM.SubWorkOrderMaterialsId AND ISNULL(tmpWOM.IsKit, 0) = 1;

			UPDATE P    
				    SET WorkOrderMaterialsId = 0, 
					       IsKit = 0, IsSubWO =0, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempSubWOtbl tmp ON P.WorkOrderMaterialsId = tmp.SubWorkOrderMaterialsId
					  WHERE P.WorkOrderMaterialsId  = tmp.SubWorkOrderMaterialsId AND ISNULL(P.IsKit,0) = tmp.IsKit AND ISNULL(IsSubWO,0) = 1

			/****** Unmapped the SubWorkorder if there is no other material link with the same sub workorder in the PurchaseOrder Part ********/
			SET @TotalCount = (SELECT COUNT(1) FROM #TempPOtbl)
			IF(@TotalCount>0)
			BEGIN
				WHILE @LooPId <= @TotalCount
				BEGIN
					SELECT @PoID FROM #TempPOtbl WHERE Id = @LooPId
					IF((SELECT COUNT(1) FROM dbo.PurchaseOrderPart WITH(NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND PurchaseOrderId = @PoID) = 1)
					BEGIN
						UPDATE P    
							SET	   SubWorkOrderId = NULL, SubWorkOrderNo = NULL,
									WorkOrderMaterialsId = NULL, 
									IsKit = NULL, IsSubWO =NULL, 
									UpdatedDate = GETUTCDATE()
							FROM DBO.PurchaseOrderPart P WHERE P.SubWorkOrderId = @SubWorkOrderId AND PurchaseOrderId = @PoID
							DELETE FROM dbo.PurchaseOrderPartReference WHERE ModuleId = 5 AND ReferenceId = @SubWorkOrderId AND PurchaseOrderId = @PoID
					END
					SET @LooPId +=1 
				END
			END

			DECLARE @WorkOrderId BIGINT;
			DECLARE @MasterCompanyId INT;
			DECLARE @UpdatedBy VARCHAR(100);
			

			SELECT @WorkOrderId = WorkOrderId, @MasterCompanyId = MasterCompanyId,  @UpdatedBy = UpdatedBy FROM SubWorkOrderPartNumber WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId

			EXEC UpdateSubWorkOrderMPNCostDetail  @workOrderId = @WorkOrderId,  @subWorkOrderId = @SubWorkOrderId, @subWOPartNoId = @SubWOPartNoId, @updatedBy = @UpdatedBy, @masterCompanyId = @MasterCompanyId;

			
			IF OBJECT_ID(N'tempdb..##TempSubWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempSubWOtbl 
				END

			COMMIT  TRANSACTION
		END TRY
		
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWOMaterialsOnIssuedOrReserved' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWOPartNoId, '') + ''
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