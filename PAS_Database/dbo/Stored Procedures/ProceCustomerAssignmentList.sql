/*************************************************************           
 ** File:   [ProceCustomerAssignmentList]           
 ** Author:  
 ** Description: This stored procedure is used to Get Employee Customer Assignment list
 ** Purpose:         
 ** Date:      
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    01/09/2025   Vishal Suthar		Get UserName
    2    20/09/2025   Vishal Suthar		Fixed sorting and filtering
     
************************************************************************/
CREATE   PROCEDURE [dbo].[ProceCustomerAssignmentList]
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = NULL,
	@MasterCompanyId bigint = NULL,
	@EmployeeId bigint = NULL,
	@CustomerName varchar(100) = NULL,
	@IsPrimary bit = NULL,
	@IsSecondary bit = NULL,
	@IsAgent bit = NULL,
	@IsCSR bit = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	    DECLARE @MSModuleID INT = 47; -- Employee Management Structure Module ID
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;
		
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		
		;WITH EmpRoleAgg AS (
			SELECT ER.EmployeeId,
				STRING_AGG(UR.Name, ', ') AS EmpRoles
			FROM dbo.EmployeeUserRole ER WITH (NOLOCK)
			INNER JOIN dbo.UserRole UR WITH (NOLOCK) ON ER.RoleId = UR.Id
			WHERE ER.IsDeleted = 0 AND ER.IsActive = 1
			GROUP BY ER.EmployeeId
		),

		Result AS(									
		   	SELECT DISTINCT CS.CustomerId,
				CUST.[Name] AS CustomerName,
				CASE WHEN EMP_P.EmployeeId = @EmployeeId THEN 1 ELSE 0 END AS IsPrimary,
				CASE WHEN EMP_S.EmployeeId = @EmployeeId THEN 1 ELSE 0 END AS IsSecondary,
				CASE WHEN EMP_A.EmployeeId = @EmployeeId THEN 1 ELSE 0 END AS IsAgent,
				CASE WHEN EMP_C.EmployeeId = @EmployeeId THEN 1 ELSE 0 END AS IsCSR
            FROM dbo.CustomerSales CS WITH (NOLOCK)
			    LEFT JOIN dbo.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = CS.CustomerId
			    LEFT JOIN dbo.Employee EMP_P WITH (NOLOCK) ON EMP_P.EmployeeId = CS.PrimarySalesPersonId
				LEFT JOIN dbo.Employee EMP_S WITH (NOLOCK) ON EMP_S.EmployeeId = CS.SecondarySalesPersonId
				LEFT JOIN dbo.Employee EMP_A WITH (NOLOCK) ON EMP_A.EmployeeId = CS.SaId
				LEFT JOIN dbo.Employee EMP_C WITH (NOLOCK) ON EMP_C.EmployeeId = CS.CsrId
		 	WHERE CS.MasterCompanyId = @MasterCompanyId
			AND (
				 CS.PrimarySalesPersonId = @EmployeeId
				  OR CS.SecondarySalesPersonId = @EmployeeId
				  OR CS.SaId = @EmployeeId
				  OR CS.CsrId = @EmployeeId
			)
			), 
			ResultCount AS (SELECT COUNT(CustomerId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result r
			WHERE ((@GlobalFilter <>'' AND (CustomerName LIKE '%' +@GlobalFilter+'%'))	
				OR   
				(@GlobalFilter = '' AND (ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName +'%') AND 
				(@IsPrimary IS NULL OR CAST(IsPrimary AS BIT) = CAST(@IsPrimary AS BIT)) AND
				(@IsSecondary IS NULL OR CAST(IsSecondary AS BIT) = CAST(@IsSecondary AS BIT)) AND
				(@IsAgent IS NULL OR CAST(IsAgent AS BIT) = CAST(@IsAgent AS BIT)) AND
				(@IsCSR IS NULL OR CAST(IsCSR AS BIT) = CAST(@IsCSR AS BIT))))

			SELECT @Count = COUNT(CustomerId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  

			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsPrimary')  THEN IsPrimary END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsPrimary')  THEN IsPrimary END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsSecondary')  THEN IsSecondary END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSecondary')  THEN IsSecondary END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsAgent')  THEN IsAgent END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsAgent')  THEN IsAgent END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsCSR')  THEN IsCSR END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCSR')  THEN IsCSR END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END TRY    
	BEGIN CATCH
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProceCustomerAssignmentList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			  + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			  + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			  + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			  + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			  + '@Parameter6 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END