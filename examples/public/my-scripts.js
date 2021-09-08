$('.my-custom-textbox input').off('keyup').on('keyup', (e) => {
    console.log($(e.target).val());
})