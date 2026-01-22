/*************************************************************           
  ** File:   [USP_GetSalesPersonActivityTypeByCustomerId]           
  ** Author:   Vishal Suthar
  ** Description: This stored procedure is used to get SalesPerson Activity Type By CustomerId
  ** Purpose:         
  ** Date:  04-Sept-2025 
          
  ** RETURN VALUE: 
  **************************************************************           
   ** Change History           
  **************************************************************           
  ** PR   Date			Author			Change Description            
  ** --   --------		-------			--------------------------------          
     1    04-Sept-2025  Vishal Suthar	Created
      
  exec [dbo].[USP_GetSalesPersonActivityTypeByCustomerId] @CustomerId=4468, @IsDeleted=0
 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalesPersonActivityTypeByCustomerId]
    @CustomerId BIGINT,
    @IsDeleted BIT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @MSModuelId INT;

		SELECT @MSModuelId = ManagementStructureModuleId FROM DBO.ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'SalespersonActivity';

		SELECT
			c.SalesPersonActivityTypeId,
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
			c.MasterCompanyId,
			c.CreatedBy,
			c.UpdatedBy,
			c.CreatedDate,
			c.UpdatedDate,
			c.IsActive,
			c.IsDeleted,
			MSD.LastMSLevel,        
			MSD.AllMSlevels,
			E.FirstName + ' ' + E.LastName AS AssignedSalesperson
		FROM [dbo].[SalesPersonActivityType] c WITH(NOLOCK)
		INNER JOIN dbo.ManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuelId AND MSD.ReferenceID = c.SalesPersonActivityTypeId
		LEFT JOIN [Percent] P_REV WITH (NOLOCK) ON P_REV.PercentId = c.RevenuePercentageId
		LEFT JOIN [Percent] P_MAR WITH (NOLOCK) ON P_MAR.PercentId = c.MarginPercentageId
		LEFT JOIN dbo.CustomerSales CS WITH (NOLOCK) ON CS.CustomerId = c.CustomerId
		LEFT JOIN dbo.Employee E WITH (NOLOCK) ON E.EmployeeId = 
        CASE 
            WHEN c.DropdownTypeId = 1 THEN CS.PrimarySalesPersonId
            WHEN c.DropdownTypeId = 2 THEN CS.SecondarySalesPersonId
            WHEN c.DropdownTypeId = 3 THEN CS.SaId
            WHEN c.DropdownTypeId = 4 THEN CS.CSRId
        END
		WHERE c.CustomerId = @CustomerId
		AND c.IsActive = 1 AND c.IsDeleted = @IsDeleted;
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
 		,@DatabaseName VARCHAR(100) = db_name()
 		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
 		,@AdhocComments VARCHAR(150) = 'USP_GetSalesPersonActivityTypeByCustomerId'
 		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) + ''     
 		,@ApplicationName VARCHAR(100) = 'PAS'
 		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
 		EXEC spLogException @DatabaseName = @DatabaseName
 			,@AdhocComments = @AdhocComments
 			,@ProcedureParameters = @ProcedureParameters
 			,@ApplicationName = @ApplicationName
 			,@ErrorLogID = @ErrorLogID OUTPUT;
 		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
 		RETURN (1);
	END CATCH
END