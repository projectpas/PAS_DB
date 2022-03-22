
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/30/2020   Hemant Saliya Created
	2    07/19/2021   Hemant Saliya Added SP Call for WO Status Update
     
-- EXEC [UpdateWorkOrderPartNumberColumnsWithId] 30
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderPartNumberColumnsWithId]
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

				SELECT * FROM #WorkOrderPartMSDATA

				UPDATE WPN SET 
					WPN.Level1 = WMS.Level1,
					WPN.Level2 = WMS.Level2,
					WPN.Level3 = WMS.Level3,
					WPN.Level4 = WMS.Level4
				FROM dbo.WorkOrderPartNumber WPN WITH(NOLOCK) 
				LEFT JOIN #WorkOrderPartMSDATA WMS ON WMS.MSID = WPN.ManagementStructureId
				WHERE WPN.ID = @WorkOrderPartNumberId
		
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderPartNumberId, '') + ''
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