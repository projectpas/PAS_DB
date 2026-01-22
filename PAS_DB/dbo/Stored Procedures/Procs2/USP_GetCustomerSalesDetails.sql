/*************************************************************           
    ** File:   [USP_GetCustomerSalesDetails]           
    ** Author:   Ekta Chandegra
    ** Description: This stored procedure is used to GetCustomerSalesDetails
    ** Purpose:         
    ** Date:  06-May-2025 
            
    ** RETURN VALUE: 
    **************************************************************           
     ** Change History           
    **************************************************************           
    ** PR   Date			Author			Change Description            
    ** --   --------		-------			--------------------------------          
       1    06-May-2025   Ekta Chandegra	Created
        
    exec [dbo].[USP_GetCustomerSalesDetails] @CustomerId=4295
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerSalesDetails]
    @CustomerId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		SELECT TOP 1
			cs.CustomerSalesId,
			cs.CustomerId,
			cs.PrimarySalesPersonId,
			cs.SecondarySalesPersonId,
			cs.CsrId,
			cs.SaId,
			cs.AnnualQuota,
			cs.AnnualRevenuePotential,
			ISNULL(ps.FirstName + ' ' + ps.LastName, '') AS primarySalesPersonName,
			ISNULL(ss.FirstName + ' ' + ss.LastName, '') AS secondarySalesPersonName,
			ISNULL(csr.FirstName + ' ' + csr.LastName, '') AS CsrName,
			ISNULL(sa.FirstName + ' ' + sa.LastName, '') AS AgentName,
			cs.CreatedBy,
			cs.UpdatedBy,
			cs.MasterCompanyId,
			ISNULL(cs.IsActive,0) AS IsActive,
			ISNULL(cs.IsDeleted,0) AS IsDeleted,
			cs.CommissionPercentageId,
			ISNULL(p.PercentValue, 0) AS PercentValue
		FROM [dbo].[CustomerSales] cs WITH(NOLOCK)
		LEFT JOIN [dbo].[Employee] ps WITH(NOLOCK) ON cs.PrimarySalesPersonId = ps.EmployeeId
		LEFT JOIN [dbo].[Employee] ss WITH(NOLOCK) ON cs.SecondarySalesPersonId = ss.EmployeeId
		LEFT JOIN [dbo].[Employee] csr WITH(NOLOCK) ON cs.CsrId = csr.EmployeeId
		LEFT JOIN [dbo].[Employee] sa WITH(NOLOCK) ON cs.SaId = sa.EmployeeId
		LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON cs.CommissionPercentageId = p.PercentId
		WHERE cs.CustomerId = @CustomerId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
   			,@DatabaseName VARCHAR(100) = db_name()
   			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
   			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerSalesDetails'
   			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@CustomerId, '') AS varchar(100)) + ''
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