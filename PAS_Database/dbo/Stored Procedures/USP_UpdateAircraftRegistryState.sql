/***********************************************************
** File:  [USP_UpdateAircraftRegistryState]
** Author: Priyansh Patel
** Description: Update Aircraft Registry State by Id
** Purpose:  
** Date:   2026-03-26

** RETURN VALUE: 
**************************************************************
** Change History
**************************************************************
** PR   Date			Author			Change Description
** --   --------		-------			--------------------------------
   1   26-03-2025    Priyansh Patel	    Created - [PN-15841]

 exec  USP_UpdateAircraftRegistryState 710
***************************************************************/
CREATE       PROCEDURE [dbo].[USP_UpdateAircraftRegistryState]
    @AircraftRegistryId BIGINT,
    @MasterCompanyId    INT,
    @IsDeleted          BIT = NULL,
    @IsActive           BIT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	  BEGIN TRY
     BEGIN TRAN;

        UPDATE [dbo].[AircraftRegistryHeader] SET  
                IsDeleted = CASE 
                    WHEN @IsDeleted IS NOT NULL THEN @IsDeleted  
                    ELSE IsDeleted 
                END,

                IsActive = CASE 
                    WHEN @IsActive IS NOT NULL THEN @IsActive  
                    ELSE IsActive
                END,
            UpdatedDate = GETUTCDATE()
        WHERE AircraftRegistryId = @AircraftRegistryId 
          AND MasterCompanyId = @MasterCompanyId;

        IF @@ROWCOUNT > 0
            SELECT @AircraftRegistryId AS AircraftRegistryId;
        ELSE
            SELECT -1 AS AircraftRegistryId;

        COMMIT TRAN;

    END TRY
    BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateAircraftRegistryState' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@AircraftRegistryId AS VARCHAR(20)) , '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH	
END