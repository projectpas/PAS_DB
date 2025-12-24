/*************************************************************           
 ** File:		 [USP_GetAircraftTypeData]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get AircraftType Data.
 ** Purpose:         
 ** Date:   24-DEC-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    24-DEC-2025 		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetAircraftTypeData] @IsFromItemMaster=1, @MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetAircraftTypeData]
@IsFromItemMaster BIT,
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	
		IF(@IsFromItemMaster = 1)
		BEGIN
			SELECT 			
				[AircraftTypeId],
				[Description],
				[Memo],
				[MasterCompanyId],
				[CreatedBy],
				[CreatedDate],
				[UpdatedBy],
				[UpdatedDate],			
				ISNULL([IsActive], 0) AS IsActive,
				ISNULL([IsDeleted], 0) AS IsDeleted
			FROM [DBO].[AircraftType] WITH(NOLOCK)
			WHERE
				[IsDeleted] = 0 AND [IsActive] = 1 AND [MasterCompanyId] = @MasterCompanyId
			ORDER BY
				[Description];
		END
		ELSE
		BEGIN
		SELECT 			
				[AircraftTypeId],
				[Description],
				[Memo],
				[MasterCompanyId],
				[CreatedBy],
				[CreatedDate],
				[UpdatedBy],
				[UpdatedDate],			
				ISNULL([IsActive], 0) AS IsActive,
				ISNULL([IsDeleted], 0) AS IsDeleted
			FROM [DBO].[AircraftType] WITH(NOLOCK)
			WHERE
				[IsDeleted] = 0 AND [IsActive] = 1
			ORDER BY
				[AircraftTypeId];
		END

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAircraftTypeData'
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
	END CATCH

END