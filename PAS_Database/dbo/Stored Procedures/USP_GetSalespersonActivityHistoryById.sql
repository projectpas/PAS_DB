/*************************************************************           
  ** File:   [USP_GetSalespersonActivityHistoryById]           
  ** Author:   Vishal Suthar
  ** Description: This stored procedure is used to GetCustomerAircraftMappingAudit
  ** Purpose:         
  ** Date:  24-Sept-2025
          
  ** RETURN VALUE: 
  **************************************************************           
   ** Change History           
  **************************************************************           
  ** PR   Date			Author			Change Description            
  ** --   --------		-------			--------------------------------          
     1    24-Sept-2025  Vishal Suthar	Created
      
  exec [dbo].[USP_GetSalespersonActivityHistoryById] @SalespersonActivityId=23
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalespersonActivityHistoryById]
    @SalespersonActivityId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
 	BEGIN TRY
		DECLARE @MSModuelId INT;

		SELECT @MSModuelId = ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'SalespersonActivity';

		SELECT c.SalesPersonActivityTypeId,
			c.AuditSalesPersonActivityTypeId,
			c.CustomerId,
			c.DropdownTypeId,
			CASE WHEN c.DropdownTypeId = 1 THEN 'Primary Salesperson' WHEN c.DropdownTypeId = 2 THEN 'Secondary Salesperson' WHEN c.DropdownTypeId = 3 THEN 'Agent' ELSE 'CSR' END AS DropdownType,
			c.ActivityTypeId,
			CASE WHEN c.ActivityTypeId = 1 THEN 'MRO Activity' WHEN c.ActivityTypeId = 2 THEN 'Brokering' ELSE 'Manafacturing' END AS ActivityType,
			c.RevenuePercentageId,
			P_REV.PercentValue RevenuePercentage,
			c.MarginPercentageId,
			P_MAR.PercentValue MarginPercentage,
			c.EffectiveDate,
			c.EntityStructureId,
			c.Level1,
			c.Level2,
			c.Level3,
			c.Level4,
			c.MasterCompanyId,
			c.CreatedBy,
			c.UpdatedBy,
			c.CreatedDate,
			c.UpdatedDate,
			c.IsDeleted,
			c.IsActive,
			MSD.LastMSLevel,        
			MSD.AllMSlevels
		FROM [dbo].[SalesPersonActivityTypeAudit] c WITH(NOLOCK)
		INNER JOIN dbo.ManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = c.SalesPersonActivityTypeId
		LEFT JOIN [Percent] P_REV ON P_REV.PercentId = c.RevenuePercentageId
		LEFT JOIN [Percent] P_MAR ON P_MAR.PercentId = c.MarginPercentageId
		WHERE c.SalesPersonActivityTypeId = @SalespersonActivityId
		ORDER BY c.AuditSalesPersonActivityTypeId DESC;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
 			,@DatabaseName VARCHAR(100) = db_name()
 			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
 			,@AdhocComments VARCHAR(150) = 'USP_GetSalespersonActivityHistoryById'
 			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalespersonActivityId, '') AS varchar(100)) + ''       
 			,@ApplicationName VARCHAR(100) = 'PAS'
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