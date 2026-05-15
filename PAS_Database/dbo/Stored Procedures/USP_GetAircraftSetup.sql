/*************************************************************           
 ** File:		          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To 
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 15/05/2026          Nakul Chandigra     Created 
	exec [USP_GetAircraftSetup] 1
**************************************************************/
	CREATE   PROCEDURE [dbo].[USP_GetAircraftSetup]
	@MasterCompanyId INT
	
	AS
	BEGIN
	BEGIN TRY
    
		SELECT TOP 1
			AR.[AircraftSetupId],
			AR.[MaintenanceStatusId],
			MS.Name AS MaintenanceStatus,
			AR.[AircraftStatusId],
			ARS.Name AS AircraftStatus,
			AR.[CurrencyId],
			CU.[Code] AS Currency,
			AR.[MasterCompanyId],
			AR.[CreatedBy],
			AR.[UpdatedBy],
			AR.[CreatedDate],
			AR.[UpdatedDate],
			AR.[IsActive],
			AR.[IsDeleted]
		FROM [dbo].[AircraftSetup] AR WITH (NOLOCK)
		LEFT JOIN [dbo].[MaintenanceStatus] MS ON MS.MaintenanceStatusId = AR.MaintenanceStatusId
		LEFT JOIN [dbo].[AircraftStatus] ARS ON ARS.AircraftStatusId = AR.AircraftStatusId
		LEFT JOIN [dbo].[Currency] CU ON CU.CurrencyId = AR.CurrencyId
		WHERE AR.MasterCompanyId = @MasterCompanyId AND AR.IsDeleted = 0 AND AR.IsActive = 1
		ORDER BY AR.AircraftSetupId DESC

	END TRY
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = '[dbo].[USP_AddupdateAircraftSetup]'
				, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
				, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1); 
	END CATCH
	END