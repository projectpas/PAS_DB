
/*************************************************************           
 ** File:   [PROCAddCopyKitData]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to store Kit Details
 ** Purpose:         
 ** Date:   04/05/2023        
 ** PARAMETERS: @KitId bigint,@CopykitId bigint,@MasterCompanyId int,@CreatedBy varchar  
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/05/2023   Moin Bloch     Created

-- EXEC PROCAddCopyKitData 2386,1,1,'ADMIN User'
************************************************************************/
CREATE   PROCEDURE [dbo].[PROCAddCopyKitData]
@KitId bigint,
@CopykitId bigint,
@MasterCompanyId int,
@CreatedBy varchar(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		IF OBJECT_ID(N'tempdb..#KITPartSUM') IS NOT NULL
		BEGIN
			DROP TABLE #KITPartSUM 
		END
			
		INSERT INTO [dbo].[KitItemMasterMapping]([KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost]
		           ,[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM],[MasterCompanyId]
                   ,[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
			SELECT	@KitId,[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost]
		           ,[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM],@MasterCompanyId
                   ,@CreatedBy,@CreatedBy,GETDATE(),GETDATE(),1,0
			  FROM [dbo].[KitItemMasterMapping] WITH(NOLOCK) WHERE [KitId] = @CopykitId AND [IsActive] = 1 AND [IsDeleted] = 0;	

		CREATE TABLE #KITPartSUM
		(
			ID BIGINT NOT NULL IDENTITY, 				
			[KitId] [bigint] NULL,				
			[Qty] [int] NULL,
			[UnitCost] [decimal](18, 2) NULL,
			[ExtendedCost] [decimal](18, 2) NULL				
		)

		INSERT INTO #KITPartSUM([KitId],[Qty],[UnitCost],[ExtendedCost])
		SELECT @KitId,[Qty],[UnitCost],ISNULL([UnitCost],0) * ISNULL([Qty],0)
		 FROM [dbo].[KitItemMasterMapping] WITH(NOLOCK) WHERE [KitId] = @CopykitId AND [IsActive] = 1 AND [IsDeleted] = 0;	

		 UPDATE KM SET KM.[KitCost] = (SELECT ISNULL(SUM(ISNULL(KP.[ExtendedCost],0)),0) FROM #KITPartSUM KP 
				WHERE [KitId] = @KitId) FROM [dbo].[KitMaster] AS KM WITH (NOLOCK) WHERE [KitId] = @KitId;
				
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCAddCustomerMSData' 
              , @ProcedureParameters VARCHAR(3000)  = '@KitId = '''+ CAST(ISNULL(@KitId, '') AS varchar(100))
			                                        + '@CopykitId = ''' + CAST(ISNULL(@CopykitId, '') AS varchar(100)) 
													+ '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@CreatedBy = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)) 													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END