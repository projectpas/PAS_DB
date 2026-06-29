/*************************************************************           
 ** File:		 [USP_GetAircraftSetup]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Get AircraftSetup
 ** Purpose:         
 ** Date:   
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 15/05/2026          Nakul Chandigra    Created 
	2    19/05/2026          Nakul Chandigra    Added fields 
	3    20/05/2026          Nakul Chandigra    Added fields 
	4    22/05/2026          Bhargav Saliya     Added [SiteId] 
	5    29/05/2026          Bhargav Saliya     Added field [MaintenanceTypeId]
	6    29/06/2026          Divyesh Kathiriya  Added field ConditionId [PN-17041]

	exec [USP_GetAircraftSetup] 1
**************************************************************/
	CREATE     PROCEDURE [dbo].[USP_GetAircraftSetup]
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
			AR.UOMId,
	        AR.ItemClassificationId,
	        AR.InventoryGLSettingId,
			AR.RedIndicator,
			AR.YellowIndicator,
			AR.GreenIndicator,
			AR.ItemgroupId,
			AR.[MasterCompanyId],
			AR.[CreatedBy],
			AR.[UpdatedBy],
			AR.[CreatedDate],
			AR.[UpdatedDate],
			AR.[IsActive],
			AR.[IsDeleted],
			AR.[SiteId],
			AR.[MaintenanceTypeId] AS AircraftMaintenanceTypeId,
			AR.[ConditionId]
		FROM [dbo].[AircraftSetup] AR WITH (NOLOCK)
		LEFT JOIN [dbo].[MaintenanceStatus] MS WITH (NOLOCK) ON MS.MaintenanceStatusId = AR.MaintenanceStatusId
		LEFT JOIN [dbo].[AircraftStatus] ARS WITH (NOLOCK) ON ARS.AircraftStatusId = AR.AircraftStatusId
		LEFT JOIN [dbo].[Currency] CU WITH (NOLOCK)  ON CU.CurrencyId = AR.CurrencyId
		WHERE AR.MasterCompanyId = @MasterCompanyId AND AR.IsDeleted = 0 AND AR.IsActive = 1
		ORDER BY AR.AircraftSetupId DESC

	END TRY
	BEGIN CATCH
		  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				, @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetAircraftSetup]'
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