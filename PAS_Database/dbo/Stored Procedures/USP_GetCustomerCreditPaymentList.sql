/*****************************************************************************     
** Author:  <Devendra Shekh>    
** Create date: <03/04/2024>    
** Description: <Get Customer CreditPaymentList>    
    
EXEC [USP_GetCustomerCreditPaymentList]   
**********************   
** Change History   
**********************     

	  (mm/dd/yyyy)
** PR   Date			Author				Change Description    
** --   --------		-------				--------------------------------  
** 1    03/04/2024		Devendra Shekh		created
** 2    03/15/2024		Devendra Shekh		added vendorcode, SuspenseUnappliedNumber
** 3    03/21/2024		Devendra Shekh		ADDED new param @RecordTypeId
** 4    03/22/2024		Devendra Shekh		ADDED IsMiscellaneous to select

*****************************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetCustomerCreditPaymentList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@CustomerName varchar(50) = NULL,
@CustomerCode varchar(50) = NULL,
@ControlNum varchar(50) = NULL,
@CustomerType varchar(50) = NULL,
@RemainingAmount varchar(100) = NULL,
@ReferenceNumber varchar(50) = NULL,
@ReceiptNo varchar(50) = NULL,
@Memo varchar(500) = NULL,
@VendorName varchar(100) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@ReceiveDate  datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@SuspenseUnappliedNumber varchar(30) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@RecordTypeId int = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @IsMiscellaneous bit;
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	

		IF(ISNULL(@StatusId,0) = 0)
		BEGIN
			SET @StatusId = NULL;
		END

		IF(ISNULL(@RecordTypeId, 0) = 0)
		BEGIN
			SET @IsMiscellaneous = NULL;
		END
		ELSE IF(ISNULL(@RecordTypeId, 0) = 1)
		BEGIN
			SET @IsMiscellaneous = 1;
		END
		ELSE IF(ISNULL(@RecordTypeId, 0) = 2)
		BEGIN
			SET @IsMiscellaneous = 0;
		END

		;WITH Result AS(
				SELECT DISTINCT
						CCP.CustomerCreditPaymentDetailId,
						CCP.CustomerId,
						CCP.CustomerName,
						CCP.CustomerCode,
						CCP.CheckNumber AS 'ReferenceNumber',
						CCP.TotalAmount,
						CCP.RemainingAmount,
						CCP.PaidAmount,
						CCP.ReceiptId,
						CCP.IsActive,
						CCP.IsDeleted,
						CCP.CreatedDate,
						CCP.UpdatedDate,
						CCP.ReceiveDate,
						CP.ReceiptNo,
						CP.CntrlNum AS 'ControlNum',
						--CASE WHEN UPPER(CCP.CustomerName) = 'MISCELLANEOUS' OR UPPER(CCP.CustomerName) = 'MISCELLANEOUS CUSTOMER' THEN 'SUSPENSE' ELSE 'UNAPPLIED' END AS 'CustomerType',
						CASE WHEN ISNULL(CCP.IsMiscellaneous, '') = 1 THEN 'SUSPENSE' ELSE 'UNAPPLIED' END AS 'CustomerType',
						Upper(CCP.CreatedBy) CreatedBy,
						Upper(CCP.UpdatedBy) UpdatedBy,
						CCP.[StatusId],
						ISNULL(CCP.Memo, '') AS 'Memo',
						ISNULL(VA.VendorName, '') AS 'VendorName',
						ISNULL(CCP.VendorId, 0) AS 'VendorId',
						ISNULL(VA.VendorCode, '') AS 'VendorCode',
						ISNULL(CCP.SuspenseUnappliedNumber, '') AS 'SuspenseUnappliedNumber',
						ISNULL(CCP.IsMiscellaneous, '') AS 'IsMiscellaneous'
					FROM dbo.CustomerCreditPaymentDetail CCP WITH (NOLOCK)
					LEFT JOIN dbo.[CustomerPayments] CP WITH (NOLOCK) ON CP.ReceiptId = CCP.ReceiptId
					LEFT JOIN [dbo].[Vendor] VA WITH(NOLOCK) ON VA.VendorId = CCP.VendorId
		 	  WHERE (CCP.[StatusId]=@StatusId OR @StatusId IS NULL) AND CCP.MasterCompanyId=@MasterCompanyId
					AND (ISNULL(CCP.IsMiscellaneous, 0)=@IsMiscellaneous OR @IsMiscellaneous IS NULL) 
			), ResultCount AS(SELECT COUNT(CustomerCreditPaymentDetailId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((CustomerName LIKE '%' +@GlobalFilter+'%') OR
			        (CustomerCode LIKE '%' +@GlobalFilter+'%') OR	
					(ControlNum LIKE '%' +@GlobalFilter+'%') OR
					(CustomerType LIKE '%' +@GlobalFilter+'%') OR
					(CAST(RemainingAmount AS VARCHAR) LIKE '%' +@GlobalFilter+'%') OR
					(ReferenceNumber LIKE '%' +@GlobalFilter+'%') OR
					(ReceiptNo LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(SuspenseUnappliedNumber LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName+'%') AND 
					(ISNULL(@CustomerCode,'') ='' OR CustomerCode LIKE '%' + @CustomerCode + '%') AND	
					(ISNULL(@ControlNum,'') ='' OR ControlNum LIKE '%' + @ControlNum + '%') AND	
					(ISNULL(@CustomerType,'') ='' OR CustomerType LIKE '%' + @CustomerType + '%') AND	
					(ISNULL(@RemainingAmount,'') ='' OR CAST(RemainingAmount AS VARCHAR) LIKE '%' + @RemainingAmount + '%') AND 
					(ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumber LIKE '%' + @ReferenceNumber + '%') AND	
					(ISNULL(@ReceiptNo,'') ='' OR ReceiptNo LIKE '%' + @ReceiptNo + '%') AND	
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo + '%') AND	
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND	
					(ISNULL(@SuspenseUnappliedNumber,'') ='' OR SuspenseUnappliedNumber LIKE '%' + @SuspenseUnappliedNumber + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND 
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@ReceiveDate,'') ='' OR CAST(ReceiveDate AS Date)=CAST(@ReceiveDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(CustomerCreditPaymentDetailId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerCode')  THEN CustomerCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerCode')  THEN CustomerCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNum')  THEN ControlNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNum')  THEN ControlNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerType')  THEN CustomerType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerType')  THEN CustomerType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RemainingAmount')  THEN RemainingAmount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RemainingAmount')  THEN RemainingAmount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReferenceNumber')  THEN ReferenceNumber END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiptNo')  THEN ReceiptNo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiptNo')  THEN ReceiptNo END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Memo')  THEN Memo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo')  THEN Memo END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='SuspenseUnappliedNumber')  THEN SuspenseUnappliedNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SuspenseUnappliedNumber')  THEN SuspenseUnappliedNumber END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReceiveDate')  THEN ReceiveDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceiveDate')  THEN ReceiveDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC			
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetCustomerCreditPaymentList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CustomerCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ReferenceNumber , '') AS varchar(100))	
			   + '@Parameter10 = ''' + CAST(ISNULL(@RemainingAmount , '') AS varchar(100))		  
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END