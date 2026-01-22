-- =============================================
-- Author:		Ameet Prajapati
-- Create date: 12 Dec 2020
-- Description:	generate Version number
-- =============================================
CREATE FUNCTION [dbo].[GenearteVersionNumber]
(
	@Number as varchar(50)
)
RETURNS varchar(50)
AS
BEGIN
	Declare @NumberLength int 
	Declare @CodeSuffix varchar(50)
	Declare @CodePrefix varchar(50)
	Declare @VersionCode varchar(50)
	Select @CodeSuffix=IsNull(CodeSufix,''),@CodePrefix=IsNull(CodePrefix,'') from CodePrefixes Where CodePrefix='Ver' and IsDeleted=0 and IsActive=1
	Set @NumberLength=LEN(@Number)

	If @NumberLength=1
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'000' + @Number+ '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='000' + @Number + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'000' + @Number
		End
		Else
		Begin 
			Set @VersionCode='000' + @Number
		End
	End
	Else If @NumberLength=2
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'00' + @Number+ '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='00' + @Number + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'00' + @Number
		End
		Else
		Begin 
			Set @VersionCode='00' + @Number
		End
	End
	Else If @NumberLength=3
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'0' + @Number+ '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode='0' + @Number + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+'0' + @Number
		End
		Else
		Begin 
			Set @VersionCode='0' + @Number
		End
	End
	Else
	Begin
		If @CodePrefix <>'' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@CodePrefix+'-'+ @Number+ '-'+ @CodeSuffix
		End
		Else If @CodePrefix ='' and @CodeSuffix <>''
		Begin
			Set @VersionCode=@Number + '-'+ @CodeSuffix
		End
		Else If @CodePrefix<>'' and @CodeSuffix =''
		Begin
			Set @VersionCode=@CodePrefix+'-'+ @Number
		End
		Else
		Begin 
			Set @VersionCode= @Number
		End
	End
	return @VersionCode


END