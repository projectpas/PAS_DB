/*************************************************************
 ** File:   [USP_CreateUpdateLeaseHeader]
 ** Description: This stored procedure is used to Create/Update a record in [LeaseHeader].
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    04/08/2026     Amit Ghediya            Created

exec USP_CreateUpdateLeaseHeader
@LeaseHeaderId=0,@LeaseName=N'Test Lease',@LeaseTypeId=1,@LeaseStatusId=1,@ManagementStructureId=1,
@CustomerId=1,@CustomerRef=N'REF-1',@CustomerContactId=1,@Email=N'test@test.com',@SalespersonEmployeeId=NULL,
@LocalCurrencyId=1,@ForeignCurrencyId=NULL,@LeaseAdministratorEmployeeId=NULL,@Memo=NULL,@Notes=NULL,
@MasterCompanyId=1,@CreatedBy=N'admin',@UpdatedBy=N'admin'
************************************************************************/
CREATE    PROCEDURE [dbo].[USP_CreateUpdateLeaseHeader]
	@LeaseHeaderId BIGINT = 0,
	@LeaseName VARCHAR(200),
	@LeaseTypeId INT,
	@LeaseStatusId INT,
	@ManagementStructureId BIGINT,
	@CustomerId BIGINT,
	@CustomerRef VARCHAR(100),
	@CustomerContactId BIGINT,
	@Email VARCHAR(256),
	@SalespersonEmployeeId BIGINT = NULL,
	@LocalCurrencyId INT = NULL,
	@ForeignCurrencyId INT = NULL,
	@ForeignExchangeRate DECIMAL(18,6) = NULL,
	@EmployeeId BIGINT = NULL,
	@Memo VARCHAR(MAX) = NULL,
	@Notes VARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(256),
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION

		DECLARE @CodePrefix   NVARCHAR(50);
		DECLARE @CodeSuffix   NVARCHAR(50);
		DECLARE @LeaseNumber  VARCHAR(50) = NULL;
		DECLARE @CurrentNo    INT = 0;

		IF (ISNULL(@LeaseHeaderId, 0) > 0)
		BEGIN
			-- -------------------------------------------------------
			-- UPDATE existing record
			-- -------------------------------------------------------
			UPDATE [dbo].[LeaseHeader]
			SET
				LeaseName                      = @LeaseName,
				LeaseTypeId                    = @LeaseTypeId,
				LeaseStatusId                  = @LeaseStatusId,
				ManagementStructureId          = @ManagementStructureId,
				CustomerId                     = @CustomerId,
				CustomerRef                    = @CustomerRef,
				CustomerContactId              = @CustomerContactId,
				Email                          = @Email,
				SalespersonEmployeeId          = @SalespersonEmployeeId,
				LocalCurrencyId                = @LocalCurrencyId,
				ForeignCurrencyId              = @ForeignCurrencyId,
				ForeignExchangeRate            = @ForeignExchangeRate,
				EmployeeId					   = @EmployeeId,
				Memo                           = @Memo,
				Notes                          = @Notes,
				UpdatedBy                      = @UpdatedBy,
				UpdatedDate                    = GETUTCDATE()
			WHERE LeaseHeaderId = @LeaseHeaderId;

			SELECT 1 AS Status, 'Updated successfully' AS Message, *
			FROM [dbo].[LeaseHeader] WITH (NOLOCK)
			WHERE LeaseHeaderId = @LeaseHeaderId;
		END
		ELSE
		BEGIN
			-- -------------------------------------------------------
			-- Generate Lease Number
			-- -------------------------------------------------------
			DECLARE @LeaseCodeTypeId INT = (
				SELECT [CodeTypeId]
				FROM   [dbo].[CodeTypes] WITH (NOLOCK)
				WHERE  [CodeType] = 'LeaseNumber'
			);

			SELECT TOP 1
				@CodePrefix = [CodePrefix],
				@CodeSuffix = [CodeSufix]
			FROM [dbo].[CodePrefixes] WITH (NOLOCK)
			WHERE  [IsActive]        = 1
			  AND  [IsDeleted]       = 0
			  AND  [CodeTypeId]      = @LeaseCodeTypeId
			  AND  [MasterCompanyId] = @MasterCompanyId;

			IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
			BEGIN
				SELECT @CurrentNo = ISNULL([CurrentNummber], 0)
				FROM   [dbo].[CodePrefixes] WITH (NOLOCK)
				WHERE  [CodePrefix]      = @CodePrefix
				  AND  [MasterCompanyId] = @MasterCompanyId;

				IF @CurrentNo > 0
				BEGIN
					SET @CurrentNo = @CurrentNo + 1;
					UPDATE [dbo].[CodePrefixes]
					SET    [CurrentNummber] = @CurrentNo
					WHERE  [CodePrefix]      = @CodePrefix
					  AND  [MasterCompanyId] = @MasterCompanyId;
				END
				ELSE
				BEGIN
					SET @CurrentNo = (
						SELECT ISNULL([StartsFrom], 0)
						FROM   [dbo].[CodePrefixes]
						WHERE  [CodePrefix]      = @CodePrefix
						  AND  [MasterCompanyId] = @MasterCompanyId
					) + 1;

					UPDATE [dbo].[CodePrefixes]
					SET    [CurrentNummber] = @CurrentNo
					WHERE  [CodePrefix]      = @CodePrefix
					  AND  [MasterCompanyId] = @MasterCompanyId;
				END

				SET @LeaseNumber = (
					SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(
						@CurrentNo,
						ISNULL(@CodePrefix, ''),
						ISNULL(@CodeSuffix,  '')
					)
				);
			END
			ELSE
			BEGIN
				SET @LeaseNumber = (
					SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '', '')
				);
			END

			-- -------------------------------------------------------
			-- INSERT new record
			-- -------------------------------------------------------
			INSERT INTO [dbo].[LeaseHeader]
			(
				LeaseNumber,
				LeaseName,
				LeaseTypeId,
				LeaseStatusId,
				ManagementStructureId,
				CustomerId,
				CustomerRef,
				CustomerContactId,
				Email,
				SalespersonEmployeeId,
				LocalCurrencyId,
				ForeignCurrencyId,
				ForeignExchangeRate,
				EmployeeId,
				Memo,
				Notes,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				IsActive,
				IsDeleted
			)
			VALUES
			(
				@LeaseNumber,
				@LeaseName,
				@LeaseTypeId,
				@LeaseStatusId,
				@ManagementStructureId,
				@CustomerId,
				@CustomerRef,
				@CustomerContactId,
				@Email,
				@SalespersonEmployeeId,
				@LocalCurrencyId,
				@ForeignCurrencyId,
				@ForeignExchangeRate,
				@EmployeeId,
				@Memo,
				@Notes,
				@MasterCompanyId,
				@CreatedBy,
				@UpdatedBy,
				GETUTCDATE(),
				GETUTCDATE(),
				1,
				0
			);

			DECLARE @NewLeaseHeaderId BIGINT = SCOPE_IDENTITY();

			SELECT 1 AS Status, 'Created successfully' AS Message, *
			FROM [dbo].[LeaseHeader] WITH (NOLOCK)
			WHERE LeaseHeaderId = @NewLeaseHeaderId;
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
            ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            ,@AdhocComments varchar(150) = '[USP_CreateUpdateLeaseHeader]',
            @ProcedureParameters varchar(3000) = '@LeaseHeaderId = ''' + CAST(ISNULL(@LeaseHeaderId, 0) AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
	END CATCH
END