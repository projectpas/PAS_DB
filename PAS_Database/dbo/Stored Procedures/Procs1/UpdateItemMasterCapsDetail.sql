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

 EXEC UpdateItemMasterCapsDetail 20754
**************************************************************/ 

CREATE   Procedure [dbo].[UpdateItemMasterCapsDetail]
@ItemMasterId  bigint
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
---------  Item Master Capes --------------------------------------------------------------		
		UPDATE IMC SET		
		IMC.PartNumber = IM.PartNumber,
		IMC.PartDescription = (ISNULL(IM.PartDescription,'')),
		IMC.CapabilityType = (ISNULL(CT.[CapabilityTypeDesc],'')) ,
		IMC.VerifiedBy = (ISNULL(EMP.FirstName,'')+' '+ISNULL(EMP.LastName,'')) 
		FROM dbo.ItemMasterCapes IMC WITH (NOLOCK)
			INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON IMC.ItemMasterId = IM.ItemMasterId
			INNER JOIN  dbo.CapabilityType CT WITH (NOLOCK) ON IMC.CapabilityTypeId = CT.CapabilityTypeId
			LEFT JOIN  dbo.Employee EMP WITH (NOLOCK) ON IMC.VerifiedById = EMP.EmployeeId
			--LEFT JOIN #ItemMasterCapesMSDATA PMS ON PMS.MSID = IMC.ManagementStructureId
		WHERE IMC.ItemMasterId  = @ItemMasterId;
		
		SELECT partnumber AS value FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId  = @ItemMasterId ;
		
		END
		COMMIT TRANSACTION
       
	END TRY    
	BEGIN CATCH  
	   IF @@trancount > 0
	   PRINT 'ROLLBACK'
       ROLLBACK TRANSACTION;	   
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
END