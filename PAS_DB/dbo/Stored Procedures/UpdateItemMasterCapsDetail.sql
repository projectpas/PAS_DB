


/*************************************************************           
 ** File:   [UpdateItemMasterCapsDetail]           
 ** Author:   Moin Bloch
 ** Description: Update Item Master Caps All Id Wise Names
 ** Purpose: Reducing Joins         
 ** Date:   05-Apr-2021     
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05-Apr-2021    Moin Bloch   Created 

 EXEC UpdateItemMasterCapsDetail 352
**************************************************************/ 

CREATE Procedure [dbo].[UpdateItemMasterCapsDetail]
@ItemMasterId  bigint
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
---------  Item Master Capes --------------------------------------------------------------

		DECLARE @MSID as bigint
		DECLARE @Level1 as varchar(200)
		DECLARE @Level2 as varchar(200)
		DECLARE @Level3 as varchar(200)
		DECLARE @Level4 as varchar(200)

		IF OBJECT_ID(N'tempdb..#ItemMasterCapesMSDATA') IS NOT NULL
		BEGIN
			DROP TABLE #ItemMasterCapesMSDATA 
		END
		CREATE TABLE #ItemMasterCapesMSDATA
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
		INSERT INTO #MSDATA (MSID) SELECT PO.ManagementStructureId FROM dbo.ItemMasterCapes PO WITH (NOLOCK) Where PO.ItemMasterId = @ItemMasterId
		
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
		
				INSERT INTO #ItemMasterCapesMSDATA (MSID, Level1,Level2,Level3,Level4)
									SELECT @MSID,@Level1,@Level2,@Level3,@Level4
				SET @LoopID = @LoopID - 1;
		END 	
		
		UPDATE IMC SET
		IMC.Level1 = PMS.Level1,
		IMC.Level2 = PMS.Level2,
		IMC.Level3 = PMS.Level3,
		IMC.Level4 = PMS.Level4,
		IMC.PartNumber = IM.PartNumber,
		IMC.PartDescription = (ISNULL(IM.PartDescription,'')),
		IMC.CapabilityType = (ISNULL(CT.[CapabilityTypeDesc],'')) ,
		IMC.VerifiedBy = (ISNULL(EMP.FirstName,'')+' '+ISNULL(EMP.LastName,'')) 
		FROM dbo.ItemMasterCapes IMC WITH (NOLOCK)
			INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON IMC.ItemMasterId = IM.ItemMasterId
			INNER JOIN  dbo.CapabilityType CT WITH (NOLOCK) ON IMC.CapabilityTypeId = CT.CapabilityTypeId
			LEFT JOIN  dbo.Employee EMP WITH (NOLOCK) ON IMC.VerifiedById = EMP.EmployeeId
			LEFT JOIN #ItemMasterCapesMSDATA PMS ON PMS.MSID = IMC.ManagementStructureId
		WHERE IMC.ItemMasterId  = @ItemMasterId;
		
		SELECT partnumber AS value FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId  = @ItemMasterId ;
		
		END
		COMMIT TRANSACTION
       
	END TRY    
	BEGIN CATCH  
	   IF @@trancount > 0
	   PRINT 'ROLLBACK'
       ROLLBACK TRANSACTION;	   
	   IF OBJECT_ID(N'tempdb..#ItemMasterCapesMSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #ItemMasterCapesMSDATA 
	   END
	   IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #MSDATA 
	   END
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateItemMasterCapsDetail'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))			  			                                           
	   ,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
	 IF OBJECT_ID(N'tempdb..#ItemMasterCapesMSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #ItemMasterCapesMSDATA 
	   END
	   IF OBJECT_ID(N'tempdb..#MSDATA') IS NOT NULL
	   BEGIN
			DROP TABLE #MSDATA 
	   END
END