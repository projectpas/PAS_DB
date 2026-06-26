/*************************************************************
 ** File:        [USP_CreateUpdateLogbookCertificateForm]
 ** Author:      Amit Ghediya
 ** Description: save update logbook label Data.
 ** Purpose:
 ** Date:        23/JUN/2026

 ** PARAMETERS:  

 ** RETURN VALUE: 
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author			Change Description
 ** --   --------      -------			--------------------------------
    1    23/JUN/2026  Amit Ghediya      Created


 **************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateUpdateLogbookCertificateForm]
(
    @LogbookCertificateFromId BIGINT = NULL,
    @WorkorderId BIGINT,
    @workOrderPartNoId BIGINT,
    @Country VARCHAR(256) = NULL,
    @OrganizationName VARCHAR(MAX) = NULL,
    @OrganizationAddress VARCHAR(MAX) = NULL,
    @InvoiceNo VARCHAR(256) = NULL,
    @ItemName VARCHAR(256) = NULL,
    @Description VARCHAR(500) = NULL,
    @PartNumber VARCHAR(256) = NULL,
    @Reference VARCHAR(256) = NULL,
    @Quantity INT = NULL,
    @status VARCHAR(20) = NULL,
    @Remarks VARCHAR(MAX) = NULL,
    @Certifies VARCHAR(256) = NULL,
    @AuthorisedSign VARCHAR(256) = NULL,
    @AuthorizationNo VARCHAR(256) = NULL,
    @PrintedName VARCHAR(256) = NULL,
    @Date DATETIME = NULL,
    @AuthorisedSign2 VARCHAR(256) = NULL,
    @ApprovalCertificate VARCHAR(256) = NULL,
    @PrintedName2 VARCHAR(256) = NULL,
    @Date2 DATETIME = NULL,
    @PDFPath VARCHAR(MAX) = NULL,
    @EmployeeId BIGINT = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256),
	@CreatedDate DATETIME2(7) = NULL,
	@UpdatedDate DATETIME2(7) = NULL,
	@IsActive BIT = NULL,
	@IsAircraftLogBook BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF ISNULL(@LogbookCertificateFromId,0) > 0
        BEGIN
            UPDATE dbo.Work_LogbookCertificateFrom
            SET
                Country = @Country,
                OrganizationName = @OrganizationName,
                OrganizationAddress = @OrganizationAddress,
                InvoiceNo = @InvoiceNo,
                ItemName = @ItemName,
                Description = @Description,
                PartNumber = @PartNumber,
                Reference = @Reference,
                Quantity = @Quantity,
                status = @status,
                Remarks = @Remarks,
                Certifies = @Certifies,
                AuthorisedSign = @AuthorisedSign,
                AuthorizationNo = @AuthorizationNo,
                PrintedName = @PrintedName,
                [Date] = @Date,
                AuthorisedSign2 = @AuthorisedSign2,
                ApprovalCertificate = @ApprovalCertificate,
                PrintedName2 = @PrintedName2,
                Date2 = @Date2,
                PDFPath = @PDFPath,
                EmployeeId = @EmployeeId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE LogbookCertificateFromId = @LogbookCertificateFromId;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Work_LogbookCertificateFrom
            (
                WorkorderId,
                workOrderPartNoId,
                Country,
                OrganizationName,
                OrganizationAddress,
                InvoiceNo,
                ItemName,
                Description,
                PartNumber,
                Reference,
                Quantity,
                status,
                Remarks,
                Certifies,
                AuthorisedSign,
                AuthorizationNo,
                PrintedName,
                [Date],
                AuthorisedSign2,
                ApprovalCertificate,
                PrintedName2,
                Date2,
                MasterCompanyId,
                CreatedBy,
                UpdatedBy,
                CreatedDate,
                UpdatedDate,
                IsActive,
                IsDeleted,
                PDFPath,
                EmployeeId,
				IsAircraftLogBook
            )
            VALUES
            (
                @WorkorderId,
                @workOrderPartNoId,
                @Country,
                @OrganizationName,
                @OrganizationAddress,
                @InvoiceNo,
                @ItemName,
                @Description,
                @PartNumber,
                @Reference,
                @Quantity,
                @status,
                @Remarks,
                @Certifies,
                @AuthorisedSign,
                @AuthorizationNo,
                @PrintedName,
                @Date,
                @AuthorisedSign2,
                @ApprovalCertificate,
                @PrintedName2,
                @Date2,
                @MasterCompanyId,
                @CreatedBy,
                @UpdatedBy,
                GETUTCDATE(),
                GETUTCDATE(),
                1,
                0,
                @PDFPath,
                @EmployeeId,
				@IsAircraftLogBook
            );

            SET @LogbookCertificateFromId = SCOPE_IDENTITY();
        END

        COMMIT TRANSACTION;

        SELECT @LogbookCertificateFromId AS LogbookCertificateFromId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME();

        EXEC spLogException
             @DatabaseName = @DatabaseName,
             @AdhocComments = 'USP_CreateUpdateLogbookCertificateForm',
             @ProcedureParameters = '',
             @ApplicationName = 'PAS',
             @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN(1);
    END CATCH
END