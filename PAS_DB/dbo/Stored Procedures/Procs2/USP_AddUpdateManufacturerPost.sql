/*************************************************************           
 ** File:		 [USP_AddUpdateManufacturerPost]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create And Update Manufacturer.
 ** Purpose:         
 ** Date:   22-August-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    22-August-2025		Divyesh Kathiriya	Created	
    
 -- EXEC [USP_AddUpdateManufacturerPost] @ManufacturerId=0,@Name=N'Test',@Comments=N'TestComments',@MasterCompanyId=1,@CreatedBy=N'dane park',@UpdatedBy=N'dane park'
**************************************************************/
Create   PROCEDURE [DBO].[USP_AddUpdateManufacturerPost]
@ManufacturerId BIGINT,
@Name VARCHAR(100),
@Comments NVARCHAR(max) = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Error Msg
		IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpmsg    
		END   

		CREATE TABLE #tmpmsg
		(        
			msg VARCHAR(256) NULL 
		)

/***************Start Save  Manufacturer Details.***************/
		IF(ISNULL(@ManufacturerId, 0) = 0)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[Manufacturer] WITH(NOLOCK) WHERE LTRIM(RTRIM(LOWER([Name]))) = @Name AND [MasterCompanyId] = @MasterCompanyId)
			BEGIN
				INSERT INTO [DBO].[Manufacturer] (
					[Name], [Comments],	[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])	
					VALUES (
					@Name, @Comments, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

				SET @ManufacturerId = SCOPE_IDENTITY();
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Already Exist Manufacturer.');					
			END
		END
/***************End Save Manufacturer Details***************/				
/***************Start Update Manufacturer Details.***************/
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[Manufacturer] WITH(NOLOCK) WHERE LTRIM(RTRIM(LOWER([Name]))) = @Name AND [MasterCompanyId] = @MasterCompanyId AND ManufacturerId <> @ManufacturerId)
			BEGIN
				UPDATE [DBO].[Manufacturer]
				SET [Name] = @Name,
					[Comments] = @Comments,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()
				WHERE [ManufacturerId] = @ManufacturerId;
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Already Exist Manufacturer.');					
			END			
		END
/***************End Update Manufacturer Details.***************/		
		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END
		ELSE
		BEGIN			
			SELECT @ManufacturerId AS ManufacturerId;
		END				
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateManufacturerPost'
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