

/*************************************************************           
 ** File:   [UpdateItemMasterExportInfoDetails]           
 ** Author:   Moin Bloch
 ** Description: Update Item Master Export Info Id Wise Names
 ** Purpose: Reducing Joins         
 ** Date:   06-Apr-2021  
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06-Apr-2021   Moin Bloch   Created

 EXEC UpdateItemMasterExportInfoDetails 351
**************************************************************/ 

CREATE PROCEDURE [dbo].[UpdateItemMasterExportInfoDetails]
@ItemMasterId  bigint
AS
BEGIN
SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
---------  Item Master --------------------------------------------------------------
 
	    UPDATE IMEI SET   
	     ExportCountryName  = CO.countries_name,
	     ExportCurrencyName = PCU.Code,
	     ExportWeightUnitName = PUM.ShortName,
	     ExportUomName = SUMG.ShortName,
	     ExportSizeUnitOfMeasureName = ESUOM.ShortName,
	     ExportClassificationIdName = exc.[Description]
	   
	    FROM dbo.ItemMasterExportInfo IMEI WITH (NOLOCK)      
	   	  LEFT JOIN dbo.Countries CO WITH (NOLOCK) ON IMEI.ExportCountryId = CO.countries_id
	   	  LEFT JOIN dbo.Currency PCU WITH (NOLOCK) ON IMEI.ExportCurrencyId = PCU.CurrencyId 
	   	  LEFT JOIN dbo.UnitOfMeasure PUM WITH (NOLOCK) ON IMEI.ExportWeightUnit = PUM.UnitOfMeasureId
	   	  LEFT JOIN dbo.UnitOfMeasure SUMG WITH (NOLOCK) ON IMEI.ExportUomId = SUMG.UnitOfMeasureId 
	   	  LEFT JOIN dbo.UnitOfMeasure ESUOM WITH (NOLOCK) ON IMEI.ExportSizeUnitOfMeasureId = ESUOM.UnitOfMeasureId 
	   	  LEFT JOIN dbo.ExportClassification EXC WITH (NOLOCK) ON IMEI.ExportClassificationId = EXC.ExportClassificationId 
	   	  
	   WHERE IMEI.ItemMasterId = @ItemMasterId;
	   
	   SELECT partnumber AS value FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId  = @ItemMasterId;
	   
	   COMMIT TRANSACTION
   END TRY
   BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateItemMasterExportInfoDetails'
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